#!/bin/bash
# Builds a distributable iPaste.zip for a GitHub Release.
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
ARCHIVE="$DIST/iPaste.zip"

"$ROOT/Scripts/bundle.sh" "$CONFIG"

rm -rf "$DIST"
mkdir -p "$DIST"
ditto -c -k --sequesterRsrc --keepParent "$ROOT/build/iPaste.app" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" > "$DIST/iPaste.zip.sha256"

echo "> Created: $ARCHIVE"
echo "> SHA-256: $(cut -d ' ' -f 1 "$DIST/iPaste.zip.sha256")"
