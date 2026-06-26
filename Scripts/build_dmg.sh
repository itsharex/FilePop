#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-}"
IDENTITY="${2:-}"
DMG_NAME="${3:-FilePop.dmg}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SIGN_APP_IN_DMG="${SIGN_APP_IN_DMG:-1}"

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Usage: Scripts/build_dmg.sh /path/to/FilePop.app 'Developer ID Application: Team Name' [FilePop.dmg]" >&2
  echo "Optional: set NOTARY_PROFILE to a notarytool keychain profile name to submit and staple the DMG." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cp -R "$APP_PATH" "$WORK_DIR/FilePop.app"
ln -s /Applications "$WORK_DIR/Applications"

if [[ -n "$IDENTITY" && "$SIGN_APP_IN_DMG" != "0" ]]; then
  codesign --force --deep --options runtime --sign "$IDENTITY" "$WORK_DIR/FilePop.app"
fi

hdiutil create -volname "FilePop" -srcfolder "$WORK_DIR" -ov -format UDZO "$DMG_NAME"

if [[ -n "$IDENTITY" ]]; then
  codesign --force --sign "$IDENTITY" "$DMG_NAME"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$DMG_NAME" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_NAME"
fi

echo "Created $DMG_NAME"
