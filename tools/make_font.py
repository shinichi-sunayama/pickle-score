# Make a small web font with only the characters the app uses.
# Needs fonttools + brotli:  pip install fonttools brotli
# Usage: python tools/make_font.py <path to MPLUSRounded1c-Bold.ttf>
# (The source font is the Google Fonts "M PLUS Rounded 1c" Bold, SIL OFL 1.1; see web/fonts/OFL.txt.)
# Run again whenever new Japanese text is added to web/.
import sys
from pathlib import Path
from fontTools import subset

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
OUT = WEB / "fonts" / "mplus-rounded-bold.woff2"

chars = set(chr(c) for c in range(0x20, 0x7F))  # all printable ASCII
chars.update("　、。・！？（）「」〜ー：／↶↻…")
chars.update("VOICEVOX:ずんだもん四国めたん春日部つむぎ")  # voice names and credits (voices.json)
for p in WEB.rglob("*"):
    if p.suffix in {".html", ".js", ".json", ".webmanifest"} and "voices" not in p.parts[-2:-1]:
        chars.update(p.read_text(encoding="utf-8"))
chars = {c for c in chars if c.isprintable() and ord(c) >= 0x20}

opts = subset.Options()
opts.flavor = "woff2"
opts.layout_features = ["*"]
opts.name_IDs = ["*"]
opts.notdef_outline = True
font = subset.load_font(sys.argv[1], opts)
s = subset.Subsetter(opts)
s.populate(text="".join(sorted(chars)))
s.subset(font)
OUT.parent.mkdir(parents=True, exist_ok=True)
subset.save_font(font, str(OUT), opts)
print(f"{len(chars)} characters -> {OUT} ({OUT.stat().st_size // 1024} KB)")
