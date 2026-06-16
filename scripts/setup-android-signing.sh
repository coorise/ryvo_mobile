#!/usr/bin/env bash
# Prepare android/.keys/<local|dev|prod> for release builds.
#
# Local: place upload-keystore.jks + key.properties under each target folder.
# CI: pass KEYSTORE_B64 (+ password secrets); writes the same layout before build.
#
# Usage: setup-android-signing.sh <local|dev|prod> [admin|client]
set -euo pipefail

TARGET="${1:?usage: setup-android-signing.sh local|dev|prod [admin|client]}"
APP="${2:-admin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=mobile-env.sh
source "$SCRIPT_DIR/mobile-env.sh"

case "$TARGET" in
  local | dev | prod) ;;
  *)
    echo "ERROR: target must be local, dev, or prod (got: $TARGET)" >&2
    exit 1
    ;;
esac

ANDROID_DIR="$(app_flutter_dir "$APP")/android"
KEYS_DIR="$ANDROID_DIR/.keys/$TARGET"
KEYSTORE_FILE="$KEYS_DIR/upload-keystore.jks"
PROPS_FILE="$KEYS_DIR/key.properties"

mkdir -p "$KEYS_DIR"

if [[ -n "${KEYSTORE_B64:-}" ]]; then
  : "${KEYSTORE_PASSWORD:?KEYSTORE_PASSWORD is required with KEYSTORE_B64}"
  : "${KEY_PASSWORD:?KEY_PASSWORD is required with KEYSTORE_B64}"
  : "${KEY_ALIAS:?KEY_ALIAS is required with KEYSTORE_B64}"

  echo "$KEYSTORE_B64" | base64 -d >"$KEYSTORE_FILE"
  cat >"$PROPS_FILE" <<EOF
storePassword=${KEYSTORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=.keys/${TARGET}/upload-keystore.jks
EOF
  echo "==> Android signing ready (CI): $APP / $TARGET"
  exit 0
fi

if [[ -f "$PROPS_FILE" && -f "$KEYSTORE_FILE" ]]; then
  echo "==> Android signing ready (local): $APP / $TARGET"
  exit 0
fi

if [[ "${REQUIRE_ANDROID_SIGNING:-}" == "1" ]]; then
  echo "ERROR: Missing release signing for $APP ($TARGET)." >&2
  echo "       Expected:" >&2
  echo "         $KEYSTORE_FILE" >&2
  echo "         $PROPS_FILE" >&2
  SECRET_PREFIX="$(resolve_android_signing_secret_prefix "$APP" "$TARGET" 2>/dev/null || true)"
  echo "       Run: $SCRIPT_DIR/generate-android-keystore.sh $APP $TARGET" >&2
  if [[ -n "$SECRET_PREFIX" ]]; then
    echo "       CI secrets: ${SECRET_PREFIX}_KEYSTORE_BASE64 (+ password/alias)" >&2
  fi
  exit 1
fi

echo "WARN: No signing in $KEYS_DIR — release build will use the debug key." >&2
