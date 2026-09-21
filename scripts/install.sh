#!/usr/bin/env bash
# Builds, copies the app to /Applications and (re)launches it.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build.sh
APP_NAME="AgentBar"
pkill -x AgentBar 2>/dev/null || true
pkill -x AIUsageLimits 2>/dev/null || true
rm -rf "/Applications/$APP_NAME.app" "/Applications/AI Usage Limits.app"
cp -R "build/$APP_NAME.app" /Applications/
open "/Applications/$APP_NAME.app"
echo "Installed and launched /Applications/$APP_NAME.app"
