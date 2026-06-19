#!/usr/bin/env bash
# Write dart_defines.json for a Flutter app directory.
# Usage: write-dart-defines.sh <app_flutter_dir> <app_slug>
set -euo pipefail

APP_DIR="${1:?app dir required}"
APP_SLUG="${2:?app slug required}"

# shellcheck source=mobile-env.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mobile-env.sh"

case "${RYVO_DEPLOY_TARGET}" in
  local)
    : "${SUPABASE_URL:=http://10.0.2.2:8400}"
    : "${FUNCTIONS_URL:=http://10.0.2.2:8400/functions/v1}"
    : "${APP_ENV:=development}"
    ;;
  dev)
    : "${SUPABASE_URL:?Set SUPABASE_URL or DEV_SUPABASE_URL secret}"
    : "${FUNCTIONS_URL:?Set FUNCTIONS_URL or DEV_SUPABASE_FUNCTIONS_URL secret}"
    : "${APP_ENV:=development}"
    ;;
  prod)
    : "${SUPABASE_URL:?Set SUPABASE_URL or PROD_SUPABASE_URL secret}"
    : "${FUNCTIONS_URL:?Set FUNCTIONS_URL or PROD_SUPABASE_FUNCTIONS_URL secret}"
    : "${APP_ENV:=production}"
    ;;
  *)
    echo "ERROR: invalid RYVO_DEPLOY_TARGET=$RYVO_DEPLOY_TARGET" >&2
    exit 1
    ;;
esac

SUPABASE_ENV="${RYVO_SERVER_ROOT}/supabase/.env"
if [[ -z "${SUPABASE_ANON_KEY:-}" && -f "$SUPABASE_ENV" ]]; then
  SUPABASE_ANON_KEY="$(grep -E '^ANON_KEY=' "$SUPABASE_ENV" | head -1 | cut -d= -f2- || true)"
fi
if [[ -z "${GOOGLE_MAPS_API_KEY:-}" && -f "$SUPABASE_ENV" ]]; then
  GOOGLE_MAPS_API_KEY="$(grep -E '^GOOGLE_MAPS_API_KEY=' "$SUPABASE_ENV" | head -1 | cut -d= -f2- || true)"
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: SUPABASE_ANON_KEY not set (export it or add ANON_KEY to $SUPABASE_ENV)" >&2
  exit 1
fi

case "$APP_SLUG" in
  ryvo_admin) export RYVO_APP=admin ;;
  ryvo) export RYVO_APP=client ;;
  *)
    echo "ERROR: unknown APP_SLUG=$APP_SLUG" >&2
    exit 1
    ;;
esac

RELEASE_BRANCH="$(resolve_release_branch)"
RELEASE_PLATFORM="${RYVO_RELEASE_PLATFORM:-android}"
OUT="$APP_DIR/dart_defines.json"

DART_DEFINES_OUT="$OUT" \
SUPABASE_URL="$SUPABASE_URL" \
SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
FUNCTIONS_URL="$FUNCTIONS_URL" \
APP_ENV="$APP_ENV" \
DEPLOY_TARGET="$RYVO_DEPLOY_TARGET" \
UPDATE_CHANNEL="$RYVO_UPDATE_CHANNEL" \
GITHUB_REPO="$GITHUB_REPO" \
RELEASE_BRANCH="$RELEASE_BRANCH" \
RELEASE_PLATFORM="$RELEASE_PLATFORM" \
APP_SLUG="$APP_SLUG" \
GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}" \
python3 -c '
import json, os
data = {
    "SUPABASE_URL": os.environ["SUPABASE_URL"],
    "SUPABASE_ANON_KEY": os.environ["SUPABASE_ANON_KEY"],
    "FUNCTIONS_URL": os.environ["FUNCTIONS_URL"],
    "APP_ENV": os.environ["APP_ENV"],
    "DEPLOY_TARGET": os.environ["DEPLOY_TARGET"],
    "UPDATE_CHANNEL": os.environ["UPDATE_CHANNEL"],
    "GITHUB_REPO": os.environ["GITHUB_REPO"],
    "RELEASE_BRANCH": os.environ["RELEASE_BRANCH"],
    "RELEASE_PLATFORM": os.environ["RELEASE_PLATFORM"],
    "APP_SLUG": os.environ["APP_SLUG"],
}
maps = os.environ.get("GOOGLE_MAPS_API_KEY", "")
if maps:
    data["GOOGLE_MAPS_API_KEY"] = maps
with open(os.environ["DART_DEFINES_OUT"], "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
'

echo "$OUT"
