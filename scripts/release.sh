#!/bin/zsh
# Build, sign with Developer ID, package a dmg, notarize, staple.
# Usage: scripts/release.sh            (version read from the project)
#        NOTARY_PROFILE=deixis-notary scripts/release.sh
# Notarization needs a keychain profile created once with:
#   xcrun notarytool store-credentials deixis-notary --apple-id <you@icloud.com> --team-id MVAUZXPK9M
# (it asks for an app-specific password from appleid.apple.com; never put it in this script)
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM_ID=MVAUZXPK9M
IDENTITY="Developer ID Application: YUE ZHANG ($TEAM_ID)"
PROFILE="${NOTARY_PROFILE:-deixis-notary}"
OUT=build/release
DERIVED=build/DerivedData-release
VERSION=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' Deixis.xcodeproj/project.pbxproj | head -1)
DMG="$OUT/Deixis-$VERSION.dmg"

rm -rf "$OUT"; mkdir -p "$OUT"

echo "▸ Building Deixis $VERSION (Release, hardened runtime, $IDENTITY)"
xcodebuild -scheme Deixis -configuration Release -derivedDataPath "$DERIVED" build \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  ENABLE_HARDENED_RUNTIME=YES \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  -quiet

APP="$DERIVED/Build/Products/Release/Deixis.app"
cp -R "$APP" "$OUT/Deixis.app"
APP="$OUT/Deixis.app"

echo "▸ Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dvv "$APP" 2>&1 | grep -E "Authority=Developer ID|flags=|TeamIdentifier"
ENT=$(codesign -d --entitlements - "$APP" 2>/dev/null | grep -c get-task-allow || true)
[ "$ENT" = "0" ] || { echo "get-task-allow present; notarization would reject"; exit 1; }
lipo -archs "$APP/Contents/MacOS/Deixis"

echo "▸ Packaging $DMG"
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/Deixis.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Deixis" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"
rm -rf "$STAGE"
codesign --sign "$IDENTITY" --timestamp "$DMG"

if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  echo "▸ Notarizing (profile: $PROFILE)"
  xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
  xcrun stapler staple "$DMG"
  echo "▸ Gatekeeper check"
  spctl -a -t open --context context:primary-signature -vv "$DMG"
else
  echo "▸ Skipped notarization: no keychain profile '$PROFILE'."
  echo "  Create it once, then rerun:"
  echo "    xcrun notarytool store-credentials $PROFILE --apple-id <you@icloud.com> --team-id $TEAM_ID"
fi

echo "▸ Done: $DMG"
ls -la "$OUT"
