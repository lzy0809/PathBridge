#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$ROOT_DIR/PathBridge.xcworkspace}"
SCHEME="${SCHEME:-PathBridgeApp}"
APP_NAME="${APP_NAME:-PathBridgeApp.app}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$ROOT_DIR/build/release}"
ARCHIVE_PATH="$OUTPUT_ROOT/${SCHEME}.xcarchive"
EXPORT_APP_DIR="$OUTPUT_ROOT/app"
DMG_STAGE_DIR="$OUTPUT_ROOT/dmg-stage"
DMG_DIR="$OUTPUT_ROOT/dmg"
BUILD_DATE="$(date +%Y%m%d-%H%M%S)"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
VERSION_TAG="${VERSION_TAG:-$BUILD_DATE-$GIT_SHA}"

DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"
SKIP_TUIST_GENERATE="${SKIP_TUIST_GENERATE:-0}"
ALLOW_UNSIGNED_ARCHIVE="${ALLOW_UNSIGNED_ARCHIVE:-0}"
SKIP_ARCHIVE="${SKIP_ARCHIVE:-0}"

DMG_NAME="PathBridge-${VERSION_TAG}.dmg"
DMG_PATH="$DMG_DIR/$DMG_NAME"
APP_PATH_IN_ARCHIVE="$ARCHIVE_PATH/Products/Applications/$APP_NAME"
FINAL_APP_PATH="$EXPORT_APP_DIR/$APP_NAME"

echo "[release] root: $ROOT_DIR"
echo "[release] output: $OUTPUT_ROOT"
echo "[release] scheme: $SCHEME"

mkdir -p "$OUTPUT_ROOT" "$DMG_DIR"

if [[ "$SKIP_TUIST_GENERATE" != "1" ]]; then
  echo "[release] tuist generate"
  (cd "$ROOT_DIR" && tuist generate >/dev/null)
fi

if [[ "$SKIP_ARCHIVE" != "1" ]]; then
  echo "[release] xcodebuild archive"
  ARCHIVE_CMD=(
    xcodebuild archive
    -workspace "$WORKSPACE_PATH"
    -scheme "$SCHEME"
    -configuration Release
    -destination "generic/platform=macOS"
    -archivePath "$ARCHIVE_PATH"
  )

  if [[ "$ALLOW_UNSIGNED_ARCHIVE" == "1" ]]; then
    ARCHIVE_CMD+=(CODE_SIGNING_ALLOWED=NO)
  fi

  "${ARCHIVE_CMD[@]}"
else
  echo "[release] skip archive, use existing: $ARCHIVE_PATH"
fi

if [[ ! -d "$APP_PATH_IN_ARCHIVE" ]]; then
  DETECTED_APP_PATH="$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -name "*.app" -type d | head -n 1 || true)"
  if [[ -n "$DETECTED_APP_PATH" ]]; then
    APP_PATH_IN_ARCHIVE="$DETECTED_APP_PATH"
    APP_NAME="$(basename "$APP_PATH_IN_ARCHIVE")"
    FINAL_APP_PATH="$EXPORT_APP_DIR/$APP_NAME"
    echo "[release] archived app auto-detected: $APP_NAME"
  else
    echo "[release][error] archived app not found: $APP_PATH_IN_ARCHIVE" >&2
    exit 1
  fi
fi

rm -rf "$EXPORT_APP_DIR"
mkdir -p "$EXPORT_APP_DIR"
cp -R "$APP_PATH_IN_ARCHIVE" "$FINAL_APP_PATH"

if [[ -n "$DEVELOPER_ID_APPLICATION" ]]; then
  echo "[release] codesign app with: $DEVELOPER_ID_APPLICATION"
  codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$FINAL_APP_PATH"
else
  echo "[release] DEVELOPER_ID_APPLICATION not set, skip app re-sign"
fi

if [[ -n "$DEVELOPER_ID_APPLICATION" || "$ALLOW_UNSIGNED_ARCHIVE" != "1" ]]; then
  echo "[release] codesign verify app"
  codesign --verify --deep --strict --verbose=2 "$FINAL_APP_PATH"
else
  echo "[release] unsigned archive mode, skip app codesign verify"
fi

rm -rf "$DMG_STAGE_DIR"
mkdir -p "$DMG_STAGE_DIR"
cp -R "$FINAL_APP_PATH" "$DMG_STAGE_DIR/$APP_NAME"
ln -sfn /Applications "$DMG_STAGE_DIR/Applications"

rm -f "$DMG_PATH"
echo "[release] create dmg: $DMG_PATH"
hdiutil create \
  -volname "PathBridge" \
  -srcfolder "$DMG_STAGE_DIR" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  "$DMG_PATH"

if [[ -n "$DEVELOPER_ID_APPLICATION" ]]; then
  echo "[release] codesign dmg with: $DEVELOPER_ID_APPLICATION"
  codesign --force --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$DMG_PATH"
  codesign --verify --verbose=2 "$DMG_PATH"
else
  echo "[release] DEVELOPER_ID_APPLICATION not set, skip dmg sign"
fi

if [[ -n "$NOTARYTOOL_PROFILE" ]]; then
  if [[ -z "$DEVELOPER_ID_APPLICATION" ]]; then
    echo "[release][error] notary requires signed dmg (set DEVELOPER_ID_APPLICATION)" >&2
    exit 1
  fi
  echo "[release] notarize dmg with profile: $NOTARYTOOL_PROFILE"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

echo "[release] generate sha256"
shasum -a 256 "$DMG_PATH" | tee "$DMG_PATH.sha256"

echo
echo "[release] done"
echo "  app: $FINAL_APP_PATH"
echo "  dmg: $DMG_PATH"
echo "  sha: $DMG_PATH.sha256"
