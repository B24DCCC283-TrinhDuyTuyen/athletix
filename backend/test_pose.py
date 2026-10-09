"""
Script kiem tra nhanh YOLO11-Pose va module phan tich dang chay Athletix.
"""
import sys
from pathlib import Path
from PIL import Image

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Them thu muc hien tai vao sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from config import DEVICE, YOLO_POSE_MODEL
from core.pose_analyzer import PoseAnalyzer

def main():
    print("=" * 60)
    print("[ATHLETIX] KIEM TRA MO HINH YOLO11-POSE")
    print(f"[*] Thiet bi: {DEVICE.upper()}")
    print(f"[*] Mo hinh: {YOLO_POSE_MODEL}")
    print("=" * 60)

    print("\n[*] Dang khoi tao PoseAnalyzer va nap mo hinh...")
    analyzer = PoseAnalyzer()

    # Su dung anh mau tu ultralytics assets hoac tao anh test
    from ultralytics.utils import ASSETS
    sample_path = ASSETS / "bus.jpg"
    if not sample_path.exists():
        sample_path = ASSETS / "zidane.jpg"

    if sample_path.exists():
        print(f"[*] Dang chay thu nghiem tren anh mau: {sample_path}")
        image = Image.open(sample_path)
    else:
        print("[*] Tao anh thu nghiem 640x640...")
        image = Image.new("RGB", (640, 640), color=(240, 240, 240))

    print("[*] Dang phan tich dang chuyen dong...")
    result = analyzer.analyze(image)

    print(f"\n[+] Ket qua phan tich:")
    print(f" - So nguoi phat hien: {result['num_athletes']}")

    for idx, ath in enumerate(result["athletes"]):
        print(f"\n--- NGUOI / VDV #{idx + 1} ---")
        metrics = ath["metrics"]
        print(f" * Goc gap goi trai: {metrics['left_knee_angle']} do")
        print(f" * Goc gap goi phai: {metrics['right_knee_angle']} do")
        print(f" * Goc khuu tay trai: {metrics['left_elbow_angle']} do")
        print(f" * Goc khuu tay phai: {metrics['right_elbow_angle']} do")
        print(f" * Do nghieng than nguoi: {metrics['trunk_angle']} do")
        print(f" * Khoang cach 2 mat ca chan: {metrics['stride_pixels']} px")
        
        print(" * Nhan xet ky thuat:")
        for fb in ath["feedbacks"]:
            print(f"    - {fb}")

    output_path = Path(__file__).parent / "test_result.jpg"
    result["annotated_image"].save(output_path)
    print(f"\n[+] Da luu anh ket qua tai: {output_path}")
    print("[*] Hoan tat kiem tra thanh cong!")

if __name__ == "__main__":
    main()
