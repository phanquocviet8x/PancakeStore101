#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Auto-detect project/scheme (fallback)
PROJECT="${PROJECT:-}"
SCHEME="${SCHEME:-}"
APP_NAME="${APP_NAME:-}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$(pwd)/build/DerivedData}"
OUTDIR="${OUTDIR:-$(pwd)/build/out}"
MIN_IOS="${MIN_IOS:-16.0}"

if [[ -z "$PROJECT" ]]; then
  if [[ -d "PancakeStore.xcodeproj" ]]; then
    PROJECT="PancakeStore.xcodeproj"
  elif [[ -d "MuffinStoreJailed.xcodeproj" ]]; then
    PROJECT="MuffinStoreJailed.xcodeproj"
  else
    echo "[-] Could not find .xcodeproj. Set PROJECT=YourProject.xcodeproj"
    exit 1
  fi
fi

if [[ -z "$SCHEME" ]]; then
  # best-guess scheme
  if [[ "$PROJECT" == "PancakeStore.xcodeproj" ]]; then
    SCHEME="PancakeStore"
  else
    SCHEME="MuffinStoreJailed"
  fi
fi

if [[ -z "$APP_NAME" ]]; then
  APP_NAME="$SCHEME"
fi

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
  echo "    You may need to set APP_NAME=... (actual .app name) or SCHEME=..."
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
