# Generate the app icons (needs Pillow): python tools/make_icons.py
# If docs/art/icon/app_icon_gemini.png (or .jpg) exists, the icons are made from it
# (center square crop, transparency filled). Otherwise a simple placeholder is drawn.
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "web" / "icons"
SOURCES = [ROOT / "docs" / "art" / "icon" / f"app_icon_gemini.{ext}" for ext in ("png", "jpg", "jpeg", "webp")]
BG = (46, 125, 87)
BALL = (240, 200, 80)
HOLE = (205, 160, 50)


def placeholder(size):
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


def from_source(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    side = min(w, h)
    im = im.crop(((w - side) // 2, (h - side) // 2, (w - side) // 2 + side, (h - side) // 2 + side))
    flat = Image.new("RGBA", im.size, (251, 243, 228, 255))  # cream behind any transparency
    flat.alpha_composite(im)
    return flat.convert("RGB")


def main():
    src = next((p for p in SOURCES if p.exists()), None)
    OUT.mkdir(parents=True, exist_ok=True)
    if src:
        base = from_source(src)
        make = lambda size: base.resize((size, size), Image.LANCZOS)
        print("from", src.relative_to(ROOT))
    else:
        make = placeholder
        print("placeholder (no docs/art/icon/app_icon_gemini.*)")
    make(192).save(OUT / "icon-192.png")
    make(512).save(OUT / "icon-512.png")
    make(180).save(OUT / "apple-touch-icon.png")
    print("icons written to", OUT)


if __name__ == "__main__":
    main()
