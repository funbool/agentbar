#!/usr/bin/env bash
# Usage: ./scripts/release.sh 0.2.0
# Bumps the version in Packaging/Info.plist, commits, tags vX.Y.Z and pushes; GitHub Actions builds and publishes the release.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?version required, e.g. 0.2.0}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must look like 1.2.3"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; exit 1; }
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Packaging/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" Packaging/Info.plist
git add Packaging/Info.plist
git commit -qm "Release v$VERSION"
git tag "v$VERSION"
git push origin HEAD "v$VERSION"
echo "Pushed v$VERSION — watch: gh run watch"
