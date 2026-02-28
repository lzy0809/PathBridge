#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/release/generate_cask.sh \
#   --version 0.1.0 \
#   --dmg-name PathBridge-20260228-112227-82dd1a2.dmg \
#   --sha256 <sha256> \
#   --output /path/to/homebrew-tap/Casks/pathbridge.rb

VERSION=""
DMG_NAME=""
SHA256=""
OUTPUT=""
SOURCE_REPO="${SOURCE_REPO:-lzy0809/PathBridge}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --dmg-name)
      DMG_NAME="$2"
      shift 2
      ;;
    --sha256)
      SHA256="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" || -z "$DMG_NAME" || -z "$SHA256" || -z "$OUTPUT" ]]; then
  echo "Missing required arguments" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" <<CASK
cask "pathbridge" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/$SOURCE_REPO/releases/download/v#{version}/$DMG_NAME"
  name "PathBridge"
  desc "Open Finder directory in your selected terminal"
  homepage "https://github.com/$SOURCE_REPO"

  app "PathBridgeApp.app"

  zap trash: [
    "~/Library/Containers/com.liangzhiyuan.pathbridge",
    "~/Library/Preferences/com.liangzhiyuan.pathbridge.plist"
  ]
end
CASK

echo "Generated cask: $OUTPUT"
