#!/bin/bash
set -euo pipefail

# Builds NetNewsWire for Mac with the Release configuration and installs it as /Applications/NNW+.app.
# Keeps the debug bundle ID and app group so NNW+ keeps its own prefs and doesn't collide with NetNewsWire.app.
# Ad-hoc signed with no entitlements, so unsandboxed like a debug build; SKIP_APP_GROUP_ACCESS avoids the app group prompt.

PROJECT_PATH="NetNewsWire.xcodeproj"
SCHEME_MAC="NetNewsWire"
DESTINATION_APP="/Applications/NNW+.app"

WORK_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "$WORK_DIRECTORY"' EXIT

cd "$(dirname "$0")/.."

echo "🛠 Building Release..."
xcodebuild \
	-project "$PROJECT_PATH" \
	-scheme "$SCHEME_MAC" \
	-configuration Release \
	-destination "platform=macOS,arch=arm64" \
	-derivedDataPath "$WORK_DIRECTORY/DerivedData" \
	BUNDLE_ID_SUFFIX=-DEBUG \
	APP_GROUP_SUFFIX=-DEBUG \
	CODE_SIGN_IDENTITY=- \
	CODE_SIGN_STYLE=Manual \
	DEVELOPMENT_TEAM= \
	CODE_SIGN_ENTITLEMENTS= \
	ENABLE_HARDENED_RUNTIME=NO \
	CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
	'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) SKIP_APP_GROUP_ACCESS' \
	-quiet \
	build

BUILT_APP="$WORK_DIRECTORY/DerivedData/Build/Products/Release/NetNewsWire.app"

plutil -replace CFBundleName -string "NNW+" "$BUILT_APP/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "NNW+" "$BUILT_APP/Contents/Info.plist"
codesign --force --sign - "$BUILT_APP"
codesign --verify --deep --strict "$BUILT_APP"

osascript -e 'quit app "NNW+"' 2>/dev/null || true
rm -rf "$DESTINATION_APP"
ditto "$BUILT_APP" "$DESTINATION_APP"

echo "✅ $DESTINATION_APP"
