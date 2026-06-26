#!/usr/bin/env bash
set -euo pipefail

IDENTITY="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_PATH="$DIST_DIR/FilePop.xcarchive"
EXPORT_PATH="$DIST_DIR/export"
EXPORT_OPTIONS="$DIST_DIR/ExportOptions.plist"

cd "$ROOT_DIR"

mkdir -p "$DIST_DIR"

if [[ -n "$IDENTITY" ]]; then
  TEAM_ID="$(sed -E 's/.*\(([A-Z0-9]+)\)$/\1/' <<< "$IDENTITY")"
  if [[ "$TEAM_ID" == "$IDENTITY" ]]; then
    echo "Could not extract Team ID from signing identity: $IDENTITY" >&2
    echo "Expected format: Developer ID Application: Name (TEAMID)" >&2
    exit 1
  fi

  rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$EXPORT_OPTIONS"

  xcodebuild \
    -project FilePop.xcodeproj \
    -scheme FilePop \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    archive

  cat > "$EXPORT_OPTIONS" <<EOF_EXPORT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>developer-id</string>
	<key>signingCertificate</key>
	<string>$IDENTITY</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>thinning</key>
	<string>&lt;none&gt;</string>
</dict>
</plist>
EOF_EXPORT

  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

  APP_PATH="$EXPORT_PATH/FilePop.app"
else
  xcodebuild \
    -project FilePop.xcodeproj \
    -scheme FilePop \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    build

  APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*/Build/Products/Release/FilePop.app' \
    -print -quit)"
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Release build did not produce FilePop.app" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/FilePop-${VERSION}-${BUILD}-macOS.dmg"
ZIP_PATH="$DIST_DIR/FilePop-${VERSION}-${BUILD}-macOS.zip"
NOTES_PATH="$DIST_DIR/RELEASE_NOTES-${VERSION}-${BUILD}.md"

rm -f "$DMG_PATH" "$ZIP_PATH" "$DIST_DIR/SHA256SUMS.txt" "$NOTES_PATH"

SIGN_APP_IN_DMG=0 Scripts/build_dmg.sh "$APP_PATH" "$IDENTITY" "$DMG_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" "$(basename "$ZIP_PATH")" > SHA256SUMS.txt
)

cat > "$NOTES_PATH" <<EOF_NOTES
# FilePop ${VERSION} (${BUILD})

## Downloads

- FilePop-${VERSION}-${BUILD}-macOS.dmg: recommended installer.
- FilePop-${VERSION}-${BUILD}-macOS.zip: fallback archive containing FilePop.app.
- SHA256SUMS.txt: SHA256 checksums for release assets.

## Install

1. Quit FilePop if it is running.
2. Open the DMG.
3. Drag FilePop.app to Applications.
4. Launch FilePop from Applications.
5. Enable the Finder extension in System Settings > Privacy & Security > Extensions > Finder Extensions.

## Signing

For public GitHub distribution, build with a Developer ID Application certificate and notarize the DMG:

\`\`\`sh
NOTARY_PROFILE=FilePopNotary Scripts/package_release.sh "Developer ID Application: Your Name (TEAMID)"
\`\`\`
EOF_NOTES

if [[ -n "$IDENTITY" ]]; then
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
fi
hdiutil verify "$DMG_PATH"

echo "Created release assets in $DIST_DIR"
