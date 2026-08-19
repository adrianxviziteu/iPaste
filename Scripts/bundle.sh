#!/bin/bash
# Assembles iPaste.app from the binary SwiftPM produces.
# Replaces the step Xcode would normally do, so we can work without it.
set -euo pipefail

CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/.build/$CONFIG"
APP="$ROOT/build/iPaste.app"
BUNDLE_ID="com.adrianviziteu.ipaste"
VERSION="0.1.0"

echo "> Building ($CONFIG)..."
swift build -c "$CONFIG" --package-path "$ROOT"

echo "> Assembling the bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD_DIR/iPaste" "$APP/Contents/MacOS/iPaste"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>iPaste</string>
    <key>CFBundleDisplayName</key>       <string>iPaste</string>
    <key>CFBundleExecutable</key>        <string>iPaste</string>
    <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key>           <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>    <string>14.0</string>
    <!-- Lives in the menu bar: no Dock icon, no main window. -->
    <key>LSUIElement</key>               <true/>
    <key>NSHumanReadableCopyright</key>  <string>(c) $(date +%Y) Adrian Viziteu</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>iPaste pastes saved content into the app you are using.</string>
</dict>
</plist>
PLIST

# How this is signed decides whether the Accessibility permission survives a rebuild.
#
# An ad-hoc signature is not an identity: its cdhash changes on every compile, so
# macOS sees a different app each time and asks for the permission again, while the
# old tick stays in the list belonging to a build that no longer exists.
#
# With a real signing identity - a self-signed code-signing certificate from your
# own keychain is enough - the signature stays put and the grant holds.
IDENTITY="${IPASTE_SIGN_IDENTITY:-}"

if [ -n "$IDENTITY" ]; then
    echo "> Signing as: $IDENTITY"
    codesign --force --sign "$IDENTITY" --timestamp=none "$APP"
else
    echo "> Signing ad-hoc - no code-signing identity found"
    echo "  WARNING: the Accessibility permission will be invalidated on every rebuild."
    echo "  See the 'Stable signing' section of the README to fix this once."
    codesign --force --sign - --timestamp=none "$APP" 2>/dev/null
fi

echo "> Done: $APP"
