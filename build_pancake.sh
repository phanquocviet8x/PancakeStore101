#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[-] xcodebuild not found. This script must run on macOS with Xcode installed."
  exit 1
fi

PROJECT="${PROJECT:-PancakeStore.xcodeproj}"
SCHEME="${SCHEME:-PancakeStore}"
APP_NAME="${APP_NAME:-PancakeStore}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$(pwd)/build/DerivedData}"
OUTDIR="${OUTDIR:-$(pwd)/build/out}"
MIN_IOS="${MIN_IOS:-16.0}"

DEBUG=0
for arg in "$@"; do
  if [[ "$arg" == "--debug" ]]; then
    CONFIGURATION="Debug"
    DEBUG=1
  fi
done

echo "[*] Building $APP_NAME ($CONFIGURATION) from $PROJECT / scheme $SCHEME"
rm -rf build
mkdir -p "$OUTDIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination 'generic/platform=iOS' \
  clean build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS"

APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "[-] Built .app not found at: $APP_PATH"
  exit 1
fi

WORKAPP="$OUTDIR/${APP_NAME}.app"
cp -R "$APP_PATH" "$WORKAPP"

echo "[*] Stripping signature..."
codesign --remove "$WORKAPP" || true
rm -rf "$WORKAPP/_CodeSignature" || true
rm -f  "$WORKAPP/embedded.mobileprovision" || true

echo "[*] Packaging IPA..."
PAYLOAD="$OUTDIR/Payload"
rm -rf "$PAYLOAD"
mkdir -p "$PAYLOAD"
cp -R "$WORKAPP" "$PAYLOAD/${APP_NAME}.app"

IPA_NAME="${APP_NAME}.ipa"
if [[ $DEBUG -eq 1 ]]; then
  IPA_NAME="${APP_NAME}.debug.ipa"
fi

(
  cd "$OUTDIR"
  /usr/bin/zip -qry "$IPA_NAME" Payload
)

echo "[+] Done: $OUTDIR/$IPA_NAME"
