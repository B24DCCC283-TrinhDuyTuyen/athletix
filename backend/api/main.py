"""
Athletix - FastAPI Backend Server
Cung cấp API phân tích dáng chạy và kỹ thuật điền kinh cho ứng dụng Athletix (Ảnh & Video).
"""
import io
import uuid
import base64
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from PIL import Image

from config import DEVICE, YOLO_POSE_MODEL, MEDIA_DIR, PROCESSED_DIR, UPLOADS_DIR
from core.pose_analyzer import PoseAnalyzer
from core.video_analyzer import VideoAnalyzer

app = FastAPI(
    title="Athletix AI API",
    description="Nền tảng phân tích kỹ thuật điền kinh bằng YOLO11-Pose (Ảnh & Video)",
    version="1.1.0"
)

# Phục vụ file video đã xử lý cho client
app.mount("/media", StaticFiles(directory=str(MEDIA_DIR)), name="media")

# Cấu hình CORS để Flutter Web/Mobile/Desktop có thể gọi API trực tiếp
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Khởi tạo mô hình Pose Analyzer & Video Analyzer
analyzer: Optional[PoseAnalyzer] = None
video_analyzer: Optional[VideoAnalyzer] = None

@app.on_event("startup")
async def startup_event():
    global analyzer, video_analyzer
    try:
        analyzer = PoseAnalyzer()
        video_analyzer = VideoAnalyzer()
        print(f"✅ Loaded YOLO11-Pose Engine on device: {DEVICE}")
    except Exception as e:
        print(f"⚠️ Warning: Could not pre-load model: {e}")

def get_analyzer() -> PoseAnalyzer:
    global analyzer
    if analyzer is None:
        analyzer = PoseAnalyzer()
    return analyzer

def get_video_analyzer() -> VideoAnalyzer:
    global video_analyzer
    if video_analyzer is None:
        video_analyzer = VideoAnalyzer()
    return video_analyzer

@app.get("/")
def read_root():
    return {
        "service": "Athletix AI Engine",
        "status": "online",
        "model": YOLO_POSE_MODEL,
        "device": DEVICE,
        "capabilities": ["image_analysis", "video_analysis"]
    }

@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "device": DEVICE,
        "model": YOLO_POSE_MODEL,
        "capabilities": ["image", "video"]
    }

@app.post("/api/analyze")
async def analyze_pose(
    file: UploadFile = File(...),
    conf: float = Form(0.35),
    iou: float = Form(0.45)
):
    """
    Nhận file ảnh chụp động tác điền kinh -> phân tích khung xương, các góc khớp và nhận xét.
    Trả về dữ liệu JSON kèm ảnh đã vẽ khung xương dạng Base64.
    """
    # Kiểm tra định dạng ảnh an toàn
    if file.content_type and not (file.content_type.startswith("image/") or file.content_type == "application/octet-stream"):
        raise HTTPException(status_code=400, detail="Vui lòng tải lên file định dạng ảnh hợp lệ.")

    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))

        # Phân tích dáng chạy
        pose_engine = get_analyzer()
        result = pose_engine.analyze(image, conf=conf, iou=iou)

        # Chuyển ảnh vẽ skeleton sang Base64 để Flutter hiển thị ngay
        buffered = io.BytesIO()
        result["annotated_image"].save(buffered, format="JPEG", quality=85)
        annotated_b64 = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return JSONResponse(content={
            "success": True,
            "num_athletes": result["num_athletes"],
            "athletes": result["athletes"],
            "annotated_image_base64": f"data:image/jpeg;base64,{annotated_b64}"
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi phân tích ảnh: {str(e)}")

@app.post("/api/analyze-video")
async def analyze_video(
    file: UploadFile = File(...),
    conf: float = Form(0.35),
    max_duration: int = Form(30)
):
    """
    Nhận file video quay cảnh chạy/điền kinh -> trích xuất chuỗi thời gian góc độ,
    tính Cadence (nhịp bước SPM), vẽ HUD phân tích lên từng khung hình và trả về link video kèm thống kê.
    """
    video_id = str(uuid.uuid4())[:8]
    ext = Path(file.filename or "video.mp4").suffix or ".mp4"
    upload_path = UPLOADS_DIR / f"raw_{video_id}{ext}"
    output_filename = f"analyzed_{video_id}.mp4"
    output_path = PROCESSED_DIR / output_filename

    try:
        # Lưu file video tải lên
        contents = await file.read()
        with open(upload_path, "wb") as f:
            f.write(contents)

        # Xử lý phân tích video bằng GPU
        vid_engine = get_video_analyzer()
        analysis_data = vid_engine.analyze_video(
            input_video_path=str(upload_path),
            output_video_path=str(output_path),
            conf=conf,
            max_duration_seconds=max_duration
        )

        analysis_data["video_url"] = f"/media/processed/{output_filename}"
        analysis_data["video_id"] = video_id

        # Dọn dẹp file thô tải lên để tiết kiệm dung lượng
        try:
            upload_path.unlink(missing_ok=True)
        except Exception:
            pass

        return JSONResponse(content=analysis_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi phân tích video: {str(e)}")
