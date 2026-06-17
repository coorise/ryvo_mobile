#!/usr/bin/env bash
# CI: build signed Android release APK and stage it for GitHub Releases.
# Usage: ci-build-release.sh <admin|client> <dev|prod>
set -euo pipefail

APP="${1:?usage: ci-build-release.sh admin|client dev|prod}"
TARGET="${2:?usage: ci-build-release.sh admin|client dev|prod}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=mobile-env.sh
source "$SCRIPT_DIR/mobile-env.sh"

export RYVO_APP="$APP"
export RYVO_DEPLOY_TARGET="$TARGET"
export RYVO_UPDATE_CHANNEL="${RYVO_UPDATE_CHANNEL:-remote}"

APP_SLUG="$(resolve_app_slug "$APP")"
APP_DIR="$(app_flutter_dir "$APP")"

case "${APP}-${TARGET}" in
  admin-dev) APK_NAME="ryvo_admin-dev.apk" ;;
  admin-prod) APK_NAME="ryvo_admin.apk" ;;
  client-dev) APK_NAME="ryvo-dev.apk" ;;
  client-prod) APK_NAME="ryvo.apk" ;;
  *)
    echo "ERROR: unknown app/target: ${APP}-${TARGET}" >&2
    exit 1
    ;;
esac

chmod +x "$SCRIPT_DIR"/*.sh "$APP_DIR"/*.sh "$APP_DIR"/scripts/*.sh 2>/dev/null || true
"$SCRIPT_DIR/set-package-id.sh" "$APP" "$TARGET"
REQUIRE_ANDROID_SIGNING=1 "$SCRIPT_DIR/setup-android-signing.sh" "$TARGET" "$APP"

(
  cd "$APP_DIR"
  ./run_build.sh release "--$TARGET"
)

mkdir -p "$MOBILE_ROOT/.github_releases/mobile/android"
cp "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" \
  "$MOBILE_ROOT/.github_releases/mobile/android/$APK_NAME"

RAW="$(grep '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}')"
TAG_VERSION="$(echo "$RAW" | tr '+' '-')"
if [[ "$TARGET" == "prod" ]]; then
  TAG="${APP_SLUG}-v${TAG_VERSION}"
else
  TAG="${APP_SLUG}-${TARGET}-v${TAG_VERSION}"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "raw=$RAW"
    echo "tag=$TAG"
    echo "apk_name=$APK_NAME"
    echo "app_slug=$APP_SLUG"
  } >>"$GITHUB_OUTPUT"
fi

echo "==> staged $APK_NAME (tag: $TAG, version: $RAW)"
