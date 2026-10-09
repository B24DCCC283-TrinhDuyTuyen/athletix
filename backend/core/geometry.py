import math
from typing import Tuple, Optional

Point = Tuple[float, float]

def calculate_angle(a: Point, b: Point, c: Point) -> float:
    """
    Tính góc ở đỉnh b tạo bởi 3 điểm a - b - c (theo độ, 0 - 180).
    Ví dụ: Hông (a) - Gối (b) - Mắt cá chân (c) để tính góc gập gối.
    """
    v1 = (a[0] - b[0], a[1] - b[1])
    v2 = (c[0] - b[0], c[1] - b[1])

    dot_product = v1[0] * v2[0] + v1[1] * v2[1]
    mag1 = math.hypot(v1[0], v1[1])
    mag2 = math.hypot(v2[0], v2[1])

    if mag1 == 0 or mag2 == 0:
        return 0.0

    cosine_angle = dot_product / (mag1 * mag2)
    # Giới hạn trong [-1, 1] để tránh lỗi làm tròn số thực
    cosine_angle = max(-1.0, min(1.0, cosine_angle))

    angle = math.degrees(math.acos(cosine_angle))
    return round(angle, 1)

def calculate_vertical_angle(top: Point, bottom: Point) -> float:
    """
    Tính góc nghiêng của đoạn thẳng (bottom -> top) so với trục thẳng đứng.
    Ví dụ: Đoạn thẳng Hông (bottom) -> Vai (top) để đo độ đổ người (trunk lean).
    Góc 0 độ là người đứng thẳng đứng.
    """
    dx = top[0] - bottom[0]
    dy = top[1] - bottom[1]  # Trong hệ tọa độ ảnh, trục y hướng xuống dưới

    # Đoạn thẳng hướng lên (dy âm khi top ở trên bottom)
    # Ta tính góc so với trục Y âm (thẳng đứng hướng lên)
    angle_rad = math.atan2(abs(dx), -dy) if dy != 0 else math.pi / 2
    return round(math.degrees(angle_rad), 1)

def calculate_distance(a: Point, b: Point) -> float:
    """Khoảng cách Euclid giữa 2 điểm (pixel)."""
    return round(math.hypot(a[0] - b[0], a[1] - b[1]), 2)
