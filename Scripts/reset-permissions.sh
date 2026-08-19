#!/bin/bash
# Clears iPaste's Accessibility grants and reinstalls the app to a stable location.
#
# Why this is needed once: while the app was signed ad-hoc, every rebuild produced
# a different signature, so macOS recorded a separate grant each time. Those old
# records still sit in the Accessibility list — ticked, but belonging to builds
# that no longer exist. The current, properly signed app is not covered by any of
# them, which is why it keeps asking.
#
# Run this yourself: it changes privacy settings, so it needs to be your action.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="com.adrianviziteu.ipaste"
BUILT="$ROOT/build/iPaste.app"
INSTALLED="/Applications/iPaste.app"

echo "> Quitting iPaste..."
killall iPaste 2>/dev/null || true

echo "> Clearing old Accessibility records for $BUNDLE_ID..."
tccutil reset Accessibility "$BUNDLE_ID" || true

echo "> Building a fresh signed bundle..."
"$ROOT/Scripts/bundle.sh" >/dev/null

echo "> Installing to $INSTALLED..."
# A fixed home outside the build folder: rebuilds no longer delete the very bundle
# the permission was granted to.
rm -rf "$INSTALLED"
ditto "$BUILT" "$INSTALLED"

echo "> Signature of the installed app:"
codesign -dv --verbose=2 "$INSTALLED" 2>&1 | grep -E "Identifier|Authority" | sed 's/^/    /'

echo "> Launching..."
open "$INSTALLED"

cat <<'NOTE'

Next, once:
  1. iPaste will ask for Accessibility access - grant it.
  2. If System Settings still lists older iPaste entries, remove them with the
     minus button. They belong to builds that no longer exist.

From now on rebuilds keep the grant, because the signature no longer changes.
To update the installed copy later:  ./Scripts/install.sh
NOTE
