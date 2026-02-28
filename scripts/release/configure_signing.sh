#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_SWIFT="$ROOT_DIR/Project.swift"

usage() {
  cat <<'EOF'
Usage:
  scripts/release/configure_signing.sh [--team TEAM_ID]

What it does:
  1) Prints detected code signing identities and Team IDs.
  2) Prints whether 'Developer ID Application' identity exists.
  3) Optionally applies DEVELOPMENT_TEAM into Project.swift.

Examples:
  scripts/release/configure_signing.sh
  scripts/release/configure_signing.sh --team XXXXXXXXXX
EOF
}

TEAM_ID=""
if [[ ${1:-} == "--team" ]]; then
  TEAM_ID="${2:-}"
  if [[ -z "$TEAM_ID" ]]; then
    echo "error: missing TEAM_ID" >&2
    usage
    exit 1
  fi
  if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
    echo "error: TEAM_ID must be 10 chars of A-Z/0-9, got: $TEAM_ID" >&2
    exit 1
  fi
elif [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "error: unknown argument: $1" >&2
  usage
  exit 1
fi

echo "== Code signing identities =="
IDENTITIES="$(security find-identity -v -p codesigning || true)"
echo "$IDENTITIES"

echo
echo "== Team IDs (from identities) =="
echo "$IDENTITIES" | sed -nE 's/.*\(([A-Z0-9]{10})\)"$/\1/p' | sort -u

echo
echo "== Developer ID Application identities =="
DEV_ID_LIST="$(echo "$IDENTITIES" | rg 'Developer ID Application' || true)"
if [[ -z "$DEV_ID_LIST" ]]; then
  echo "(none)"
  echo "You still need to create/install Developer ID Application certificate before external distribution."
else
  echo "$DEV_ID_LIST"
fi

echo
echo "== Current project signing snapshot =="
(
  cd "$ROOT_DIR"
  xcodebuild -showBuildSettings -scheme PathBridgeApp 2>/dev/null | rg 'PRODUCT_BUNDLE_IDENTIFIER|_DEVELOPMENT_TEAM_IS_EMPTY|DEVELOPMENT_TEAM'
)

if [[ -n "$TEAM_ID" ]]; then
  echo
  echo "== Applying DEVELOPMENT_TEAM=$TEAM_ID to Project.swift =="

  if rg -q '"DEVELOPMENT_TEAM"\s*:' "$PROJECT_SWIFT"; then
    perl -0777 -i -pe "s/\"DEVELOPMENT_TEAM\"\s*:\s*\"[A-Z0-9]{10}\",/\"DEVELOPMENT_TEAM\": \"$TEAM_ID\",/g" "$PROJECT_SWIFT"
  else
    perl -0777 -i -pe "s/\"MACOSX_DEPLOYMENT_TARGET\"\s*:\s*\"14\.0\",/\"MACOSX_DEPLOYMENT_TARGET\": \"14.0\",\n            \"DEVELOPMENT_TEAM\": \"$TEAM_ID\",/g" "$PROJECT_SWIFT"
  fi

  echo "Applied. Re-run 'tuist generate' if needed before archive/build."
fi

echo
echo "== Suggested next command for release build =="
echo 'DEVELOPER_ID_APPLICATION="Developer ID Application: <Name> (<TEAM_ID>)" scripts/release/make_dmg.sh'
