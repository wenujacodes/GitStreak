#!/usr/bin/env bash
set -euo pipefail

# Scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

VERSION="${1:-1.0.0}"
BUILD_DIR="./build"
RELEASE_DIR="$BUILD_DIR/Build/Products/Release"
ZIP_PATH="$BUILD_DIR/GitStreak-v${VERSION}.zip"

echo "==> Building GitStreak for Release (Version ${VERSION})..."
xcodebuild build \
  -project GitStreak.xcodeproj \
  -scheme GitStreak \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES

echo "==> Creating ZIP archive: ${ZIP_PATH}"
rm -f "$ZIP_PATH"
(cd "$RELEASE_DIR" && zip -r -q "$PROJECT_DIR/$ZIP_PATH" GitStreak.app)

SIGN_UPDATE_TOOL=""
if [[ -f "./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" ]]; then
  SIGN_UPDATE_TOOL="./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
elif [[ -f "./build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" ]]; then
  SIGN_UPDATE_TOOL="./build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
fi

if [[ -n "$SIGN_UPDATE_TOOL" && -x "$SIGN_UPDATE_TOOL" ]]; then
  echo "==> Computing Sparkle Ed25519 signature..."
  SIGNATURE_OUTPUT=$("$SIGN_UPDATE_TOOL" "$ZIP_PATH")
  echo "--------------------------------------------------------"
  echo "Sparkle Enclosure Attributes for appcast.xml:"
  echo "$SIGNATURE_OUTPUT"
  echo "--------------------------------------------------------"
else
  echo "Warning: sign_update tool not found at expected path."
fi

echo "==> Release archive ready at: ${ZIP_PATH}"
