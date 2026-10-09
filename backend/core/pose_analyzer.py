"""
Athletix - Pose Analyzer sử dụng YOLO11-Pose (17 COCO Keypoints)
Chuyên dùng phân tích kỹ thuật và chuyển động điền kinh (chạy nước rút, chạy bền).
"""
from typing import Dict, Any, List, Optional
import numpy as np
from PIL import Image
import cv2

from config import DEVICE, YOLO_POSE_MODEL, YOLO_POSE_PATH
from core.geometry import calculate_angle, calculate_vertical_angle, calculate_distance

# Chỉ số 17 điểm COCO Keypoints
KEYPOINT_NAMES = [
    "nose",           # 0
    "left_eye",       # 1
    "right_eye",      # 2
    "left_ear",       # 3
    "right_ear",      # 4
    "left_shoulder",  # 5
    "right_shoulder", # 6
    "left_elbow",     # 7
    "right_elbow",    # 8
    "left_wrist",     # 9
    "right_wrist",    # 10
    "left_hip",       # 11
    "right_hip",      # 12
    "left_knee",      # 13
    "right_knee",     # 14
    "left_ankle",     # 15
    "right_ankle"     # 16
]

class PoseAnalyzer:
    def __init__(self, weights: Optional[str] = None):
        from ultralytics import YOLO
        if weights is None:
            weights = str(YOLO_POSE_PATH) if YOLO_POSE_PATH.exists() else YOLO_POSE_MODEL
        self.model = YOLO(weights)
        self.device = 0 if DEVICE == "cuda" else "cpu"

    def analyze(
        self,
        image: Image.Image,
        conf: float = 0.35,
        iou: float = 0.45
    ) -> Dict[str, Any]:
        """
        Nhận ảnh PIL, suy luận khung xương và tính toán các góc kỹ thuật điền kinh.
        """
        # Dự đoán với YOLO11-Pose
        results = self.model.predict(
            image.convert("RGB"),
            conf=conf,
            iou=iou,
            device=self.device,
            verbose=False
        )

        result = results[0]
        athletes = []

        # Ảnh vẽ khung xương mặc định từ Ultralytics
        annotated_bgr = result.plot()
        annotated_pil = Image.fromarray(annotated_bgr[..., ::-1])

        if result.keypoints is not None and len(result.keypoints) > 0:
            xy_data = result.keypoints.xy.cpu().numpy()      # shape (N, 17, 2)
            conf_data = result.keypoints.conf.cpu().numpy() if result.keypoints.conf is not None else None
            boxes = result.boxes.xyxy.cpu().numpy() if result.boxes is not None else []

            for i in range(len(xy_data)):
                pts = xy_data[i]
                cfs = conf_data[i] if conf_data is not None else [1.0] * 17
                box = [round(float(v), 1) for v in boxes[i]] if i < len(boxes) else []

                athlete_info = self._process_single_skeleton(pts, cfs, box)
                athletes.append(athlete_info)

        return {
            "num_athletes": len(athletes),
            "athletes": athletes,
            "annotated_image": annotated_pil
        }

    def _process_single_skeleton(
        self,
        points: np.ndarray,
        confs: np.ndarray,
        box: List[float]
    ) -> Dict[str, Any]:
        """Tính toán các góc và đưa ra phản hồi kỹ thuật cho 1 người."""
        kps: Dict[str, Dict[str, Any]] = {}
        for idx, name in enumerate(KEYPOINT_NAMES):
            kps[name] = {
                "x": round(float(points[idx][0]), 1),
                "y": round(float(points[idx][1]), 1),
                "conf": round(float(confs[idx]), 2)
            }

        def get_pt(name: str, min_conf: float = 0.25) -> Optional[tuple]:
            if kps[name]["conf"] >= min_conf and (kps[name]["x"] > 0 or kps[name]["y"] > 0):
                return (kps[name]["x"], kps[name]["y"])
            return None

        # 1. Tính góc gập gối (Knee Angles)
        l_hip, l_knee, l_ankle = get_pt("left_hip"), get_pt("left_knee"), get_pt("left_ankle")
        r_hip, r_knee, r_ankle = get_pt("right_hip"), get_pt("right_knee"), get_pt("right_ankle")

        left_knee_angle = calculate_angle(l_hip, l_knee, l_ankle) if (l_hip and l_knee and l_ankle) else None
        right_knee_angle = calculate_angle(r_hip, r_knee, r_ankle) if (r_hip and r_knee and r_ankle) else None

        # 2. Tính góc khuỷu tay / đánh tay (Elbow Angles)
        l_sho, l_elb, l_wri = get_pt("left_shoulder"), get_pt("left_elbow"), get_pt("left_wrist")
        r_sho, r_elb, r_wri = get_pt("right_shoulder"), get_pt("right_elbow"), get_pt("right_wrist")

        left_elbow_angle = calculate_angle(l_sho, l_elb, l_wri) if (l_sho and l_elb and l_wri) else None
        right_elbow_angle = calculate_angle(r_sho, r_elb, r_wri) if (r_sho and r_elb and r_wri) else None

        # 3. Tính độ nghiêng thân người (Trunk Lean Angle)
        # Lấy trung điểm 2 vai và trung điểm 2 hông
        trunk_angle = None
        if l_sho and r_sho and l_hip and r_hip:
            mid_shoulder = ((l_sho[0] + r_sho[0]) / 2, (l_sho[1] + r_sho[1]) / 2)
            mid_hip = ((l_hip[0] + r_hip[0]) / 2, (l_hip[1] + r_hip[1]) / 2)
            trunk_angle = calculate_vertical_angle(mid_shoulder, mid_hip)
        elif l_sho and l_hip:
            trunk_angle = calculate_vertical_angle(l_sho, l_hip)
        elif r_sho and r_hip:
            trunk_angle = calculate_vertical_angle(r_sho, r_hip)

        # 4. Khoảng cách sải chân (Ankle Stride Distance)
        stride_dist = calculate_distance(l_ankle, r_ankle) if (l_ankle and r_ankle) else None

        # 5. Phản hồi và nhận xét chuyên môn điền kinh
        feedbacks = []
        if trunk_angle is not None:
            if trunk_angle < 5.0:
                feedbacks.append("Thân người hơi thẳng đứng, có thể ngả nhẹ về phía trước (8°-15°) để tối ưu lực đẩy khi chạy.")
            elif trunk_angle > 20.0:
                feedbacks.append("Thân người ngả về phía trước quá nhiều (>20°), dễ làm giảm khả năng nâng gối và gây mỏi lưng.")
            else:
                feedbacks.append("Độ nghiêng thân người tốt (chuẩn kỹ thuật duy trì tốc độ).")

        elbow_angles = [a for a in [left_elbow_angle, right_elbow_angle] if a is not None]
        if elbow_angles:
            avg_elbow = sum(elbow_angles) / len(elbow_angles)
            if avg_elbow > 115.0:
                feedbacks.append("Cánh tay đang mở góc quá rộng. Hãy giữ góc khuỷu tay gần 90° để tối ưu quán tính đánh tay.")
            elif avg_elbow < 70.0:
                feedbacks.append("Khuỷu tay gập quá chặt, cần thả lỏng vai và dao động cánh tay tự nhiên.")
            else:
                feedbacks.append("Góc đánh tay đạt chuẩn (~90°).")

        return {
            "bbox": box,
            "metrics": {
                "left_knee_angle": left_knee_angle,
                "right_knee_angle": right_knee_angle,
                "left_elbow_angle": left_elbow_angle,
                "right_elbow_angle": right_elbow_angle,
                "trunk_angle": trunk_angle,
                "stride_pixels": stride_dist
            },
            "keypoints": kps,
            "feedbacks": feedbacks
        }
