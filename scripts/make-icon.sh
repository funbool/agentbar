#!/usr/bin/env bash
# Renders Packaging/AppIcon.svg into Packaging/AppIcon.icns with every size macOS expects.
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
qlmanage -t -s 1024 -o "$TMP" Packaging/AppIcon.svg >/dev/null 2>&1
SRC="$TMP/AppIcon.svg.png"
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"
for size in 16 32 128 256 512; do
  sips -z $size $size "$SRC" --out "$SET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double "$SRC" --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o Packaging/AppIcon.icns
rm -rf "$TMP"
echo "Wrote Packaging/AppIcon.icns"
