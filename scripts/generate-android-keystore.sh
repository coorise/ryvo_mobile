#!/usr/bin/env bash
# Generate upload-keystore.jks + key.properties under android/.keys/<local|dev|prod>/.
#
# Usage:
#   ./scripts/generate-android-keystore.sh admin dev
#   ./scripts/generate-android-keystore.sh client prod
#   ./scripts/generate-android-keystore.sh admin local
#
# Optional env (skip prompts): ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS
set -euo pipefail

APP="${1:?usage: generate-android-keystore.sh <admin|client> <local|dev|prod>}"
TARGET="${2:?usage: generate-android-keystore.sh <admin|client> <local|dev|prod>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=mobile-env.sh
source "$SCRIPT_DIR/mobile-env.sh"

case "$APP" in
  admin | client) ;;
  *)
    echo "ERROR: app must be admin or client (got: $APP)" >&2
    exit 1
    ;;
esac

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
DEFAULT_ALIAS="ryvo-${APP}-${TARGET}"
SECRET_PREFIX="$(resolve_android_signing_secret_prefix "$APP" "$TARGET")"

if [[ -f "$KEYSTORE_FILE" ]]; then
  echo "ERROR: Keystore already exists: $KEYSTORE_FILE" >&2
  echo "       Remove it first if you really want a new key." >&2
  exit 1
fi

mkdir -p "$KEYS_DIR"

if [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]]; then
  STORE_PASS="$ANDROID_KEYSTORE_PASSWORD"
  KEY_PASS="$ANDROID_KEYSTORE_PASSWORD"
  KEY_ALIAS="${ANDROID_KEY_ALIAS:-$DEFAULT_ALIAS}"
else
  read -r -p "Keystore password: " -s STORE_PASS
  echo
  KEY_PASS="$STORE_PASS"
  KEY_ALIAS="${ANDROID_KEY_ALIAS:-$DEFAULT_ALIAS}"
fi

keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=Ryvo-Line, OU=Mobile, O=Ryvo-Line, L=Montreal, ST=QC, C=CA"

cat >"$PROPS_FILE" <<EOF
storePassword=${STORE_PASS}
keyPassword=${KEY_PASS}
keyAlias=${KEY_ALIAS}
storeFile=.keys/${TARGET}/upload-keystore.jks
EOF

chmod 600 "$PROPS_FILE" "$KEYSTORE_FILE"

echo ""
echo "Created $APP / $TARGET signing:"
echo "  $KEYSTORE_FILE"
echo "  $PROPS_FILE"
echo ""

if [[ "$TARGET" == "local" ]]; then
  echo "Local-only — not uploaded to GitHub."
  exit 0
fi

echo "GitHub secrets (${SECRET_PREFIX}_*):"
echo "  ${SECRET_PREFIX}_KEYSTORE_BASE64"
echo "  ${SECRET_PREFIX}_KEYSTORE_PASSWORD"
echo "  ${SECRET_PREFIX}_KEY_PASSWORD"
echo "  ${SECRET_PREFIX}_KEY_ALIAS"
echo ""
echo "Base64 command:"
echo "  base64 -w 0 $KEYSTORE_FILE"
