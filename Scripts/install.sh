#!/bin/bash
# Copies the built app over the installed one in /Applications and relaunches it.
# Keeps the Accessibility grant: same bundle id, same signature, same location.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="/Applications/iPaste.app"

"$ROOT/Scripts/bundle.sh"
killall iPaste 2>/dev/null || true
rm -rf "$INSTALLED"
ditto "$ROOT/build/iPaste.app" "$INSTALLED"
open "$INSTALLED"
echo "> Updated and running: $INSTALLED"
