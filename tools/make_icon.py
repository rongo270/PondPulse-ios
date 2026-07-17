#!/usr/bin/env python3
"""Rasterize PondPulse's Android launcher vector (ic_launcher_foreground.xml)
into the iOS 1024x1024 AppIcon PNG, on the Android ic_launcher_background color."""
from PIL import Image, ImageDraw

SS = 4          # supersample factor
OUT = 1024
N = OUT * SS

# Viewport window: 80 units of the 108-viewport, centered on the art (54, 55).
WIN = 80.0
CX, CY = 54.0, 55.0
S = N / WIN  # px per viewport unit


def px(x, y):
    return ((x - CX) * S + N / 2, (y - CY) * S + N / 2)


def ellipse_box(cx, cy, rx, ry):
    x0, y0 = px(cx - rx, cy - ry)
    x1, y1 = px(cx + rx, cy + ry)
    return [x0, y0, x1, y1]


img = Image.new("RGB", (N, N))
d = ImageDraw.Draw(img)

# Background: vertical gradient around ic_launcher_background #0E3D4F.
top = (10, 46, 61)     # slightly lighter
bot = (9, 31, 42)      # slightly deeper
for y in range(N):
    t = y / (N - 1)
    c = tuple(round(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    d.line([(0, y), (N, y)], fill=c)

# Ripple rings (strokes).
for (rx, ry, color, w) in [
    (27, 13.5, "#7FD8EF", 2.4),
    (19, 9.5, "#A8E6F5", 2.2),
    (11, 5.5, "#D2F3FA", 2.0),
]:
    d.ellipse(ellipse_box(54, 62, rx, ry), outline=color, width=round(w * S))

# Duck body: ellipse center (54,58) rx 12 ry 10.
d.ellipse(ellipse_box(54, 58, 12, 10), fill="#FFD44D")
# Head: circle center (67.5,42) r 7.5.
d.ellipse(ellipse_box(67.5, 42, 7.5, 7.5), fill="#FFD44D")
# Neck bridge so head and body read as one bird at icon size.
d.polygon([px(58.5, 52.5), px(66.5, 44.0), px(71.5, 47.5), px(63.0, 56.5)], fill="#FFD44D")
# Beak triangle.
d.polygon([px(74, 42), px(82, 44.5), px(74, 47)], fill="#FF8A3D")
# Eye.
d.ellipse(ellipse_box(69.8, 40, 1.8, 1.8), fill="#173040")
# Wing.
d.ellipse(ellipse_box(52, 56, 6, 4.5), fill="#F5B93B")

img = img.resize((OUT, OUT), Image.LANCZOS)
img.save("/Users/rongo/Desktop/ios/PondPulse/PondPulse/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("icon written")
