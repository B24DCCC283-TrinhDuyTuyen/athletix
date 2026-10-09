"""
Athletix - Video Analyzer sử dụng YOLO11-Pose (GPU CUDA)
Phân tích chuỗi chuyển động, nhịp bước (Cadence SPM), chu kỳ sải chân và góc khớp qua từng frame video.
"""
from typing import Dict, Any, List, Optional
from pathlib import Path
import time
import numpy as np
import cv2

from config import DEVICE, YOLO_POSE_MODEL, YOLO_POSE_PATH
from core.geometry import calculate_angle, calculate_vertical_angle, calculate_distance
from core.pose_analyzer import KEYPOINT_NAMES

class VideoAnalyzer:
    def __init__(self, weights: Optional[str] = None):
        from ultralytics import YOLO
        if weights is None:
            weights = str(YOLO_POSE_PATH) if YOLO_POSE_PATH.exists() else YOLO_POSE_MODEL
        self.model = YOLO(weights)
        self.device = 0 if DEVICE == "cuda" else "cpu"

    def analyze_video(
        self,
        input_video_path: str,
        output_video_path: str,
        conf: float = 0.35,
        target_fps: Optional[int] = None,
        max_duration_seconds: int = 30
    ) -> Dict[str, Any]:
        """
        Phân tích video điền kinh theo từng frame, xuất video đã vẽ khung xương và trả về dữ liệu chuỗi thời gian.
        """
        cap = cv2.VideoCapture(input_video_path)
        if not cap.isOpened():
            raise ValueError(f"Không thể mở file video: {input_video_path}")

        orig_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / orig_fps if orig_fps > 0 else 0

        # Giới hạn số frame để xử lý nhanh chóng
        max_frames = int(orig_fps * max_duration_seconds)
        frames_to_process = min(total_frames, max_frames) if total_frames > 0 else max_frames

        # Khởi tạo VideoWriter (sử dụng codec mp4v tương thích cao)
        fourcc = cv2.VideoWriter_fourcc(*"mp4v")
        out = cv2.VideoWriter(output_video_path, fourcc, orig_fps, (width, height))

        frame_idx = 0
        time_series_data: List[Dict[str, Any]] = []
        knee_angles: List[float] = []
        trunk_angles: List[float] = []
        elbow_angles: List[float] = []

        t_start = time.perf_counter()

        while cap.isOpened() and frame_idx < frames_to_process:
            ret, frame = cap.read()
            if not ret:
                break

            timestamp = round(frame_idx / orig_fps, 2)

            # Dự đoán khung xương bằng YOLO11-Pose
            results = self.model.predict(
                frame,
                conf=conf,
                device=self.device,
                verbose=False
            )

            result = results[0]
            annotated_frame = result.plot()

            # Trích xuất góc của vận động viên chính (người có độ tin cậy hoặc kích thước lớn nhất)
            current_metrics = {
                "frame": frame_idx,
                "timestamp": timestamp,
                "left_knee_angle": None,
                "right_knee_angle": None,
                "trunk_angle": None,
                "left_elbow_angle": None,
                "right_elbow_angle": None,
            }

            if result.keypoints is not None and len(result.keypoints) > 0:
                xy = result.keypoints.xy.cpu().numpy()[0]  # Vận động viên chính
                cf = (
                    result.keypoints.conf.cpu().numpy()[0]
                    if result.keypoints.conf is not None
                    else [1.0] * 17
                )

                def get_p(idx: int):
                    if cf[idx] >= 0.25 and (xy[idx][0] > 0 or xy[idx][1] > 0):
                        return (float(xy[idx][0]), float(xy[idx][1]))
                    return None

                l_hip, l_knee, l_ank = get_p(11), get_p(13), get_p(15)
                r_hip, r_knee, r_ank = get_p(12), get_p(14), get_p(16)
                l_sho, l_elb, l_wri = get_p(5), get_p(7), get_p(9)
                r_sho, r_elb, r_wri = get_p(6), get_p(8), get_p(10)

                lk_angle = calculate_angle(l_hip, l_knee, l_ank) if (l_hip and l_knee and l_ank) else None
                rk_angle = calculate_angle(r_hip, r_knee, r_ank) if (r_hip and r_knee and r_ank) else None
                le_angle = calculate_angle(l_sho, l_elb, l_wri) if (l_sho and l_elb and l_wri) else None
                re_angle = calculate_angle(r_sho, r_elb, r_wri) if (r_sho and r_elb and r_wri) else None

                t_angle = None
                if l_sho and r_sho and l_hip and r_hip:
                    mid_s = ((l_sho[0] + r_sho[0]) / 2, (l_sho[1] + r_sho[1]) / 2)
                    mid_h = ((l_hip[0] + r_hip[0]) / 2, (l_hip[1] + r_hip[1]) / 2)
                    t_angle = calculate_vertical_angle(mid_s, mid_h)
                elif l_sho and l_hip:
                    t_angle = calculate_vertical_angle(l_sho, l_hip)

                current_metrics["left_knee_angle"] = lk_angle
                current_metrics["right_knee_angle"] = rk_angle
                current_metrics["trunk_angle"] = t_angle
                current_metrics["left_elbow_angle"] = le_angle
                current_metrics["right_elbow_angle"] = re_angle

                # Thu thập để tính toán thống kê
                active_knee = rk_angle or lk_angle
                if active_knee is not None:
                    knee_angles.append(active_knee)
                if t_angle is not None:
                    trunk_angles.append(t_angle)
                active_elbow = re_angle or le_angle
                if active_elbow is not None:
                    elbow_angles.append(active_elbow)

                # Vẽ bảng HUD hiển thị trực tiếp góc kỹ thuật lên góc khung hình
                self._draw_hud(annotated_frame, lk_angle, rk_angle, t_angle, timestamp)

            time_series_data.append(current_metrics)
            out.write(annotated_frame)
            frame_idx += 1

        cap.release()
        out.release()

        proc_time = time.perf_counter() - t_start
        actual_fps_processed = round(frame_idx / proc_time, 1) if proc_time > 0 else 0

        # Ước lượng số bước & Cadence (SPM) dựa trên chu kỳ co duỗi khớp gối
        cadence_spm, step_count = self._calculate_cadence(knee_angles, duration)

        # Tính toán các chỉ số trung bình & biên độ chuyển động
        avg_trunk = round(float(np.mean(trunk_angles)), 1) if trunk_angles else None
        max_knee = round(float(np.max(knee_angles)), 1) if knee_angles else None
        min_knee = round(float(np.min(knee_angles)), 1) if knee_angles else None
        avg_elbow = round(float(np.mean(elbow_angles)), 1) if elbow_angles else None

        feedbacks = self._generate_video_feedback(
            cadence_spm=cadence_spm,
            avg_trunk=avg_trunk,
            max_knee=max_knee,
            min_knee=min_knee,
            avg_elbow=avg_elbow
        )

        return {
            "success": True,
            "total_frames": frame_idx,
            "duration_seconds": round(duration, 2),
            "processing_fps": actual_fps_processed,
            "summary": {
                "step_count": step_count,
                "cadence_spm": cadence_spm,
                "avg_trunk_angle": avg_trunk,
                "max_knee_extension": max_knee,
                "min_knee_flexion": min_knee,
                "avg_elbow_angle": avg_elbow
            },
            "feedbacks": feedbacks,
            # Lấy mẫu chuỗi thời gian (cứ mỗi 2-3 frame lấy 1 điểm để gửi nhẹ về mobile)
            "time_series": time_series_data[::2]
        }

    def _draw_hud(
        self,
        frame: np.ndarray,
        l_knee: Optional[float],
        r_knee: Optional[float],
        trunk: Optional[float],
        timestamp: float
    ):
        """Vẽ bảng thông số kỹ thuật (HUD) lên góc trên video."""
        h, w = frame.shape[:2]
        overlay = frame.copy()
        cv2.rectangle(overlay, (20, 20), (320, 160), (15, 23, 42), -1)
        cv2.addWeighted(overlay, 0.75, frame, 0.25, 0, frame)
        cv2.rectangle(frame, (20, 20), (320, 160), (0, 230, 118), 2)

        font = cv2.FONT_HERSHEY_SIMPLEX
        cv2.putText(frame, f"ATHLETIX AI - {timestamp:.1f}s", (35, 48), font, 0.55, (0, 230, 118), 2)

        lk_str = f"{l_knee:.1f} deg" if l_knee is not None else "--"
        rk_str = f"{r_knee:.1f} deg" if r_knee is not None else "--"
        cv2.putText(frame, f"Knee L/R: {lk_str} | {rk_str}", (35, 80), font, 0.45, (255, 255, 255), 1)

        tr_str = f"{trunk:.1f} deg" if trunk is not None else "--"
        cv2.putText(frame, f"Trunk Lean: {tr_str}", (35, 110), font, 0.45, (255, 255, 255), 1)
        cv2.putText(frame, "Model: YOLO11-Pose (RTX 3050)", (35, 140), font, 0.4, (148, 163, 184), 1)

    def _calculate_cadence(self, angles: List[float], duration: float) -> tuple:
        """Thuật toán tìm cực trị chu kỳ gối để đếm số bước chân (Steps) và Cadence (SPM)."""
        if len(angles) < 10 or duration <= 0:
            return None, 0

        # Lọc nhiễu đơn giản bằng moving average
        window = 5
        smoothed = np.convolve(angles, np.ones(window)/window, mode='valid')

        # Đếm số đỉnh cực đại (extension peak)
        peaks = 0
        for i in range(1, len(smoothed) - 1):
            if smoothed[i] > smoothed[i - 1] and smoothed[i] > smoothed[i + 1] and smoothed[i] > 140:
                peaks += 1

        step_count = peaks * 2  # 1 chu kỳ hoàn chỉnh gồm 2 bước (chân trái + phải)
        cadence_spm = round((step_count / duration) * 60) if duration > 0 else None
        return cadence_spm, step_count

    def _generate_video_feedback(
        self,
        cadence_spm: Optional[int],
        avg_trunk: Optional[float],
        max_knee: Optional[float],
        min_knee: Optional[float],
        avg_elbow: Optional[float]
    ) -> List[str]:
        feedbacks = []
        if cadence_spm:
            if cadence_spm < 155:
                feedbacks.append(f"Nhịp bước chạy khá chậm (~{cadence_spm} SPM). Hãy thử tăng guồng chân lên 165-180 bước/phút để giảm lực chấn thương lên khớp gối.")
            elif cadence_spm > 195:
                feedbacks.append(f"Nhịp bước rất cao (~{cadence_spm} SPM - tốc độ nước rút tốt).")
            else:
                feedbacks.append(f"Nhịp bước đạt mức tối ưu (~{cadence_spm} SPM) cho hiệu suất điền kinh.")

        if avg_trunk is not None:
            if 8.0 <= avg_trunk <= 18.0:
                feedbacks.append(f"Độ nghiêng thân người trung bình chuẩn ({avg_trunk}°), duy trì trọng tâm tốt qua các chu kỳ.")
            elif avg_trunk < 8.0:
                feedbacks.append(f"Thân người có xu hướng quá thẳng đứng ({avg_trunk}°), nên ngả nhẹ để đón lực quán tính.")
            else:
                feedbacks.append(f"Thân người ngả về trước hơi nhiều ({avg_trunk}°), cần lưu ý cơ lõi (core).")

        if min_knee is not None and min_knee > 75:
            feedbacks.append("Biên độ gập gối khi lăng chân chưa đủ cao. Hãy tập thêm bài tập nâng cao đùi để tăng độ mở sải bước.")

        if avg_elbow is not None:
            if 80 <= avg_elbow <= 105:
                feedbacks.append(f"Biên độ đánh tay chuẩn mực (~{avg_elbow}°), giúp giữ thăng bằng và nhịp chạy tốt.")

        return feedbacks
