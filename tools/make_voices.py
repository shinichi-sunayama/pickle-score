# Generate the voice clips with a locally running VOICEVOX (http://127.0.0.1:50021).
# Usage: start the VOICEVOX app, then: python tools/make_voices.py
# Writes web/voices/<id>/n0.wav ... n40.wav, sideout.wav, second.wav, gameset.wav and web/voices/voices.json.
#
# Terms (checked 2026-11-15, see docs/voices.md): commercial use OK with the credit "VOICEVOX:<name>"
# shown somewhere users can find it (the app shows it in Settings). Do not distribute the clips as
# standalone material (二次配布).
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

ENGINE = "http://127.0.0.1:50021"
ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
OUT = WEB / "voices"

VOICES = [
    # id, character name in VOICEVOX, style name, label shown in the app
    ("zundamon", "ずんだもん", "ノーマル", "ずんだもん"),
    ("metan", "四国めたん", "ノーマル", "四国めたん"),
    ("tsumugi", "春日部つむぎ", "ノーマル", "春日部つむぎ"),
]


def get(path):
    with urllib.request.urlopen(ENGINE + path, timeout=30) as r:
        return json.loads(r.read())


def post(path, body=None, raw=False):
    data = json.dumps(body).encode() if body is not None else b""
    req = urllib.request.Request(ENGINE + path, data=data, method="POST",
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = r.read()
    return out if raw else json.loads(out)


def style_id(speakers, name, style):
    for sp in speakers:
        if sp["name"] == name:
            for st in sp["styles"]:
                if st["name"] == style:
                    return st["id"]
    raise SystemExit(f"VOICEVOX has no voice {name} / {style}")


def synth(text, speaker):
    q = post(f"/audio_query?text={urllib.parse.quote(text)}&speaker={speaker}")
    q["speedScale"] = 1.12
    q["prePhonemeLength"] = 0.03
    q["postPhonemeLength"] = 0.04
    q["outputSamplingRate"] = 24000
    q["outputStereo"] = False
    return post(f"/synthesis?speaker={speaker}", q, raw=True)


def main():
    words = json.loads((WEB / "voice-words.json").read_text(encoding="utf-8"))
    clips = {f"n{i}": w for i, w in enumerate(words["numbers"])}
    clips.update(words["phrases"])
    print("VOICEVOX", get("/version"))
    speakers = get("/speakers")
    listing = []
    for vid, name, style, label in VOICES:
        sid = style_id(speakers, name, style)
        d = OUT / vid
        d.mkdir(parents=True, exist_ok=True)
        for clip, text in clips.items():
            (d / f"{clip}.wav").write_bytes(synth(text, sid))
            time.sleep(0.02)
        listing.append({"id": vid, "name": label, "credit": f"VOICEVOX:{name}"})
        print(f"{label}: {len(clips)} clips")
    (OUT / "voices.json").write_text(json.dumps(listing, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
