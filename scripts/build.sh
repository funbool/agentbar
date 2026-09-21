#!/usr/bin/env bash
# Builds AIUsageLimits with SwiftPM and assembles a runnable .app bundle in build/.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="AI Usage Limits"
APP="build/$APP_NAME.app"

swift build -c release 2>&1 | tail -3
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/AIUsageLimits" "$APP/Contents/MacOS/AIUsageLimits"
cp Packaging/Info.plist "$APP/Contents/Info.plist"
# SwiftPM puts processed resources into a .bundle next to the binary
if [ -d "$BIN_DIR/AIUsageLimits_AIUsageLimits.bundle" ]; then
  cp -R "$BIN_DIR/AIUsageLimits_AIUsageLimits.bundle" "$APP/Contents/Resources/"
fi
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "Built: $APP"
