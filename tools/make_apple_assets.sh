#!/bin/bash
# Make the asset catalogs for the iPhone and Watch apps (needs macOS: uses sips).
# Run from the repository root: bash tools/make_apple_assets.sh
# Inputs: docs/art/icon/app_icon_gemini.jpg (icon), web/img/dogs/*.png (dog pictures).
# Outputs (not kept in git): apple/Generated/iOS.xcassets and apple/Generated/Watch.xcassets
set -euo pipefail

ICON_SRC=docs/art/icon/app_icon_gemini.jpg
OUT=apple/Generated
rm -rf "$OUT/iOS.xcassets" "$OUT/Watch.xcassets"

catalog() { # $1 = catalog dir, $2 = platform (ios / watchos)
  local cat=$1 platform=$2
  mkdir -p "$cat/AppIcon.appiconset"
  echo '{"info":{"author":"xcode","version":1}}' > "$cat/Contents.json"
  # 1024x1024 PNG with no transparency (the App Store refuses transparent icons).
  sips -s format png -z 1024 1024 "$ICON_SRC" --out "$cat/AppIcon.appiconset/icon-1024.png" > /dev/null
  cat > "$cat/AppIcon.appiconset/Contents.json" <<EOF
{"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"$platform","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
EOF
  for f in web/img/dogs/*.png; do
    local name
    name=$(basename "$f" .png)
    mkdir -p "$cat/dog_$name.imageset"
    cp "$f" "$cat/dog_$name.imageset/$name.png"
    cat > "$cat/dog_$name.imageset/Contents.json" <<EOF
{"images":[{"filename":"$name.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}
EOF
  done
}

catalog "$OUT/iOS.xcassets" ios
catalog "$OUT/Watch.xcassets" watchos
echo "asset catalogs written to $OUT"
