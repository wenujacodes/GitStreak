#!/usr/bin/env bash
set -euo pipefail

# Scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

VERSION="${1:-1.1.8}"
BUILD_NUMBER="${2:-10}"
BUILD_DIR="./build"
RELEASE_DIR="$BUILD_DIR/Build/Products/Release"
APP_PATH="$RELEASE_DIR/GitStreak.app"
ZIP_PATH="$BUILD_DIR/GitStreak-v${VERSION}.zip"
DMG_PATH="$BUILD_DIR/GitStreak-v${VERSION}.dmg"

echo "==> Regenerating Xcode Project for Version ${VERSION} (Build ${BUILD_NUMBER})..."
xcodegen generate

echo "==> Building GitStreak for Release (Version ${VERSION}, Build ${BUILD_NUMBER})..."
xcodebuild build \
  -project GitStreak.xcodeproj \
  -scheme GitStreak \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: $APP_PATH not found after build."
  exit 1
fi

echo "==> Creating ZIP archive for Sparkle: ${ZIP_PATH}"
rm -f "$ZIP_PATH"
(cd "$RELEASE_DIR" && zip -r -q "$PROJECT_DIR/$ZIP_PATH" GitStreak.app)

echo "==> Creating macOS DMG installer: ${DMG_PATH}"
rm -f "$DMG_PATH"

if command -v create-dmg &>/dev/null; then
  echo "Using create-dmg utility..."
  create-dmg \
    --volname "GitStreak Installer" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "GitStreak.app" 175 190 \
    --hide-extension "GitStreak.app" \
    --app-drop-link 425 190 \
    "$DMG_PATH" \
    "$APP_PATH" || echo "create-dmg finished with non-zero status"
else
  echo "create-dmg not found, falling back to hdiutil..."
  STAGING_DIR="$BUILD_DIR/dmg_staging"
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"
  cp -R "$APP_PATH" "$STAGING_DIR/"
  ln -s /Applications "$STAGING_DIR/Applications"
  hdiutil create -volname "GitStreak" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
  rm -rf "$STAGING_DIR"
fi

SIGN_UPDATE_TOOL=""
if [[ -f "./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" ]]; then
  SIGN_UPDATE_TOOL="./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
elif [[ -f "./build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" ]]; then
  SIGN_UPDATE_TOOL="./build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
fi

if [[ -n "$SIGN_UPDATE_TOOL" && -x "$SIGN_UPDATE_TOOL" ]]; then
  echo "==> Computing Sparkle Ed25519 signature for ZIP..."
  SIGNATURE_OUTPUT=$("$SIGN_UPDATE_TOOL" "$ZIP_PATH")
  echo "--------------------------------------------------------"
  echo "Sparkle Enclosure Attributes for appcast.xml:"
  echo "$SIGNATURE_OUTPUT"
  echo "--------------------------------------------------------"
else
  echo "Warning: sign_update tool not found at expected path."
fi

echo "==> Release artifacts ready:"
echo "    DMG: ${DMG_PATH}"
echo "    ZIP: ${ZIP_PATH}"
