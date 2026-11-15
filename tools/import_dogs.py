# Copy the Ohagi Kinako Kobo dog pictures from the chiwa-survivor project into the web app, smaller.
# Usage: python tools/import_dogs.py <path to chiwa-survivor>
# Source: chiwa-survivor/Assets/_Game/Resources/DogSprites/<dog>.png (256x256, the user's own art,
# baked from the user's Meshy models; see docs/asset-licenses.md).
import sys
from pathlib import Path
from PIL import Image

DOGS = ["ohagi", "kinako", "shiratama", "dorayaki", "yokan"]
OUT = Path(__file__).resolve().parent.parent / "web" / "img" / "dogs"


def main(src_root):
    src = Path(src_root) / "Assets" / "_Game" / "Resources" / "DogSprites"
    OUT.mkdir(parents=True, exist_ok=True)
    for d in DOGS:
        im = Image.open(src / f"{d}.png").convert("RGBA")
        im = im.crop(im.getbbox())
        im.thumbnail((180, 180), Image.LANCZOS)
        im.save(OUT / f"{d}.png", optimize=True)
        print(d, im.size, (OUT / f"{d}.png").stat().st_size // 1024, "KB")
    # Small round face of Ohagi for the "serve" mark.
    im = Image.open(src / "ohagi.png").convert("RGBA")
    face = im.crop((96, 40, 222, 166)).resize((64, 64), Image.LANCZOS)
    face.save(OUT / "ohagi_face.png", optimize=True)
    print("ohagi_face", face.size)


if __name__ == "__main__":
    main(sys.argv[1])
