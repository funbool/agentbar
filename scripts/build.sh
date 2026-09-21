#!/usr/bin/env bash
# Builds AgentBar with SwiftPM and assembles a runnable .app bundle in build/.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="AgentBar"
APP="build/$APP_NAME.app"

swift build -c release 2>&1 | tail -3
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/AgentBar" "$APP/Contents/MacOS/AgentBar"
cp Packaging/Info.plist "$APP/Contents/Info.plist"
# CI passes the git tag as VERSION so the bundle version always matches the release.
if [ -n "${VERSION:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER:-$VERSION}" "$APP/Contents/Info.plist"
fi
cp Packaging/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# SwiftPM puts processed resources into a .bundle next to the binary
if [ -d "$BIN_DIR/AgentBar_AgentBar.bundle" ]; then
  cp -R "$BIN_DIR/AgentBar_AgentBar.bundle" "$APP/Contents/Resources/"
fi
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "Built: $APP"
