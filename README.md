# FilePop

FilePop is a native macOS Finder enhancement app. Version 1 focuses on three Finder background right-click actions:

- New File
- Open Terminal Here
- Copy Folder Path

The app runs as a menu bar utility and ships a Finder Sync extension. The menu bar settings window controls the new-file mode and the template list shared with the extension.

## Requirements

- macOS 13+
- Xcode 26.5 was used for the initial project setup
- A Developer ID Application certificate and notarization are required for a public GitHub DMG that opens normally on other people's Macs.

## Build

```sh
xcodebuild -project FilePop.xcodeproj \
  -scheme FilePop \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

For a real distribution build, set your Apple development team, bundle identifiers, and App Group entitlement in Xcode, then build with signing enabled.

## Test

```sh
xcodebuild -project FilePop.xcodeproj \
  -scheme FilePopTests \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## GitHub Release Package

```sh
Scripts/package_release.sh
```

This creates release assets in `dist/`:

- `FilePop-<version>-<build>-macOS.dmg`
- `FilePop-<version>-<build>-macOS.zip`
- `SHA256SUMS.txt`
- release notes

That unsigned/development-signed package is suitable for local install testing. For public GitHub distribution, create a notarytool keychain profile and build with a Developer ID Application certificate:

```sh
NOTARY_PROFILE=FilePopNotary Scripts/package_release.sh \
  "Developer ID Application: Your Name (TEAMID)" \
```

macOS Gatekeeper checks downloaded apps from outside the Mac App Store. A DMG that is not Developer ID signed and notarized can still be uploaded to GitHub, but users will see security blocks or need manual bypass steps.

## Finder Extension Notes

The extension only returns menu items for Finder background context menus, so all actions target the current Finder directory. It monitors `/`, the user home directory, and mounted volumes under `/Volumes` to cover normal local Finder navigation.

After installing or running the app, enable the Finder extension in System Settings. macOS may require relaunching Finder before new contextual menu items appear.
