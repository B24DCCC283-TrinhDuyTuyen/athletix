import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
MODELS_DIR.mkdir(exist_ok=True)
MEDIA_DIR = BASE_DIR / "media"
PROCESSED_DIR = MEDIA_DIR / "processed"
UPLOADS_DIR = MEDIA_DIR / "uploads"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

# YOLO Pose Model Weight
YOLO_POSE_MODEL = os.getenv("YOLO_POSE_MODEL", "yolo11n-pose.pt")
YOLO_POSE_PATH = MODELS_DIR / YOLO_POSE_MODEL

# Device configuration (Auto select GPU if available)
try:
    import torch
    DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
except ImportError:
    DEVICE = "cpu"

# Server configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))
