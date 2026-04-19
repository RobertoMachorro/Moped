#!/bin/bash
#
# test-release.sh — Build Release, install to /Applications, and set up CLI
#
# Use this to test sandbox behavior locally before uploading to TestFlight.
# A Release build applies the same sandbox entitlements as TestFlight/MAS,
# so sandbox denials that only appear in production will also appear here.
#
# Usage:
#   ./scripts/test-release.sh           # build + install + symlink
#   ./scripts/test-release.sh --log     # also tail sandbox/LaunchServices logs
#
# After running this script, test from a *separate* terminal:
#   moped ~/Desktop/test.txt
#   moped --wait /tmp/test.txt

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Moped"
BUNDLE_ID="net.machorro.roberto.Moped"
INSTALL_PATH="/Applications/$APP_NAME.app"
CLI_LINK="/usr/local/bin/moped"

echo "==> Building Release..."
xcodebuild \
	-project "$PROJECT_DIR/Moped.xcodeproj" \
	-scheme "$APP_NAME" \
	-configuration Release \
	-destination 'platform=macOS' \
	build 2>&1 | tail -3

# Find the build product
BUILD_DIR=$(xcodebuild \
	-project "$PROJECT_DIR/Moped.xcodeproj" \
	-scheme "$APP_NAME" \
	-configuration Release \
	-showBuildSettings 2>/dev/null \
	| grep -m1 '^\s*BUILT_PRODUCTS_DIR' \
	| awk '{print $NF}')
BUILT_APP="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
	echo "ERROR: Build product not found at $BUILT_APP" >&2
	exit 1
fi

echo "==> Installing to $INSTALL_PATH..."
rm -rf "$INSTALL_PATH"
cp -R "$BUILT_APP" "$INSTALL_PATH"
xattr -cr "$INSTALL_PATH"  # strip quarantine

echo "==> Setting up CLI symlink..."
ln -sf "$INSTALL_PATH/Contents/Resources/moped" "$CLI_LINK"

echo "==> Verifying bundle contents..."
echo "    CLI script:"
ls -l "$INSTALL_PATH/Contents/Resources/moped"
echo "    moped-wait helper:"
ls -l "$INSTALL_PATH/Contents/Resources/moped-wait"
echo "    moped-wait entitlements:"
codesign -d --entitlements - "$INSTALL_PATH/Contents/Resources/moped-wait" 2>&1 | grep -A1 'app-sandbox'

echo ""
echo "==> Ready. Open a NEW terminal and test:"
echo "      moped ~/Desktop/test.txt"
echo "      moped --wait ~/Desktop/test.txt"
echo ""

if [ "${1:-}" = "--log" ]; then
	echo "==> Tailing sandbox and LaunchServices logs (Ctrl-C to stop)..."
	echo "    Watching for: $APP_NAME, moped, moped-wait, Sandbox, deny"
	echo ""
	log stream --level debug --predicate \
		'(process == "moped-wait") OR (process == "Moped") OR (sender == "Sandbox") OR (eventMessage CONTAINS[c] "sandbox") OR (eventMessage CONTAINS[c] "deny" AND (process == "moped-wait" OR process == "Moped"))' \
		--style compact
fi
