#!/bin/zsh
# v0.6 R50: publish build/release/Deixis-<version>.dmg as the GitHub release for tag v<major>.<minor>.
# Run scripts/release.sh first, then `git tag v0.6 && git push origin v0.6`, then this.
# The asset is uploaded as Deixis.dmg so the site's link, releases/latest/download/Deixis.dmg, never changes.
# Usage: scripts/publish.sh            (version read from the project; tag derived as vMAJOR.MINOR, or vMAJOR.MINOR.PATCH when PATCH is not 0)
#        TAG=v0.6 scripts/publish.sh   (an explicit tag)
set -euo pipefail
cd "$(dirname "$0")/.."

REPO=Malik1942/deixis
VERSION=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' Deixis.xcodeproj/project.pbxproj | head -1)
DMG="build/release/Deixis-$VERSION.dmg"
if [ -z "${TAG:-}" ]; then
  case "$VERSION" in
    *.*.0) TAG="v${VERSION%.0}" ;;
    *) TAG="v$VERSION" ;;
  esac
fi

[ -f "$DMG" ] || { echo "no $DMG; run scripts/release.sh first"; exit 1; }
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "tag $TAG does not exist; create and push it first"; exit 1; }
git ls-remote --exit-code --tags origin "$TAG" >/dev/null || { echo "tag $TAG is not on origin; git push origin $TAG"; exit 1; }
spctl -a -t open --context context:primary-signature "$DMG" 2>/dev/null || { echo "$DMG is not notarized and stapled"; exit 1; }

STAGE=$(mktemp -d)
cp "$DMG" "$STAGE/Deixis.dmg"
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  echo "▸ Release $TAG exists; replacing Deixis.dmg"
  gh release upload "$TAG" "$STAGE/Deixis.dmg" -R "$REPO" --clobber
else
  echo "▸ Creating release $TAG with Deixis.dmg"
  gh release create "$TAG" "$STAGE/Deixis.dmg" -R "$REPO" --title "Deixis $VERSION" --notes "Deixis $VERSION. Download Deixis.dmg and drag Deixis to Applications; over an older copy, the permissions carry over." --latest
fi
rm -rf "$STAGE"
echo "▸ https://github.com/$REPO/releases/latest/download/Deixis.dmg"
curl -sI "https://github.com/$REPO/releases/latest/download/Deixis.dmg" | head -1
