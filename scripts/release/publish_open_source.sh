#!/usr/bin/env bash
set -euo pipefail

# One-command automation for:
# 1) source repo bootstrap/push
# 2) GitHub release with DMG
# 3) Homebrew tap repo + cask publish

SOURCE_REPO="${SOURCE_REPO:-lzy0809/PathBridge}"
TAP_REPO="${TAP_REPO:-lzy9527/homebrew-tap}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-master}"

VERSION=""
DMG_PATH=""
RELEASE_NOTES="${RELEASE_NOTES:-Initial public release}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --dmg)
      DMG_PATH="$2"
      shift 2
      ;;
    --notes)
      RELEASE_NOTES="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  if [[ -x ".tools/gh" ]]; then
    export PATH="$(pwd)/.tools:$PATH"
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required. Install GitHub CLI first." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub auth is required. Run: gh auth login" >&2
  exit 1
fi

if ! gh repo view "$SOURCE_REPO" >/dev/null 2>&1; then
  gh repo create "$SOURCE_REPO" --public
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "git@github.com:${SOURCE_REPO}.git"
else
  git remote add origin "git@github.com:${SOURCE_REPO}.git"
fi

git push -u origin "$DEFAULT_BRANCH"

if [[ -n "$VERSION" || -n "$DMG_PATH" ]]; then
  if [[ -z "$VERSION" || -z "$DMG_PATH" ]]; then
    echo "--version and --dmg must be provided together" >&2
    exit 1
  fi
  if [[ ! -f "$DMG_PATH" ]]; then
    echo "DMG not found: $DMG_PATH" >&2
    exit 1
  fi

  TAG="v${VERSION#v}"
  SHA_FILE="${DMG_PATH}.sha256"
  shasum -a 256 "$DMG_PATH" | awk '{print $1}' > "$SHA_FILE"

  if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    git tag "$TAG"
    git push origin "$TAG"
  fi

  if ! gh release view "$TAG" >/dev/null 2>&1; then
    gh release create "$TAG" "$DMG_PATH" "$SHA_FILE" \
      --repo "$SOURCE_REPO" \
      --title "PathBridge ${TAG}" \
      --notes "$RELEASE_NOTES"
  else
    gh release upload "$TAG" "$DMG_PATH" "$SHA_FILE" --clobber --repo "$SOURCE_REPO"
  fi

  if ! gh repo view "$TAP_REPO" >/dev/null 2>&1; then
    gh repo create "$TAP_REPO" --public
  fi

  TMP_TAP="$(mktemp -d)"
  trap 'rm -rf "$TMP_TAP"' EXIT
  gh repo clone "$TAP_REPO" "$TMP_TAP"

  DMG_NAME="$(basename "$DMG_PATH")"
  SHA256="$(cat "$SHA_FILE")"
  scripts/release/generate_cask.sh \
    --version "${VERSION#v}" \
    --dmg-name "$DMG_NAME" \
    --sha256 "$SHA256" \
    --output "$TMP_TAP/Casks/pathbridge.rb"

  (
    cd "$TMP_TAP"
    git add Casks/pathbridge.rb
    if ! git diff --cached --quiet; then
      git commit -m "pathbridge ${VERSION#v}"
      git push origin HEAD
    fi
  )
fi

echo "Open-source publish workflow completed."
