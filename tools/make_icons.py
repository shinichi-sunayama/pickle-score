# Generate the app icons (needs Pillow): python tools/make_icons.py
# Simple drawing: soft green square with a yellow pickleball. Full-bleed so it also works as maskable.
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "web" / "icons"
BG = (46, 125, 87)
BALL = (240, 200, 80)
HOLE = (205, 160, 50)


def draw(size):
    s = 4  # supersample for smooth edges
    n = size * s
    img = Image.new("RGB", (n, n), BG)
    d = ImageDraw.Draw(img)
    cx, cy, r = n / 2, n / 2, n * 0.30
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=BALL)
    hr = r * 0.13
    for hx, hy in [(0, 0), (-0.48, -0.30), (0.48, -0.30), (-0.48, 0.30), (0.48, 0.30), (0, -0.58), (0, 0.58)]:
        x, y = cx + hx * r, cy + hy * r
        d.ellipse([x - hr, y - hr, x + hr, y + hr], fill=HOLE)
    return img.resize((size, size), Image.LANCZOS)


OUT.mkdir(parents=True, exist_ok=True)
draw(192).save(OUT / "icon-192.png")
draw(512).save(OUT / "icon-512.png")
draw(180).save(OUT / "apple-touch-icon.png")
print("icons written to", OUT)
