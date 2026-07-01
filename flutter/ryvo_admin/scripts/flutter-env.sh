#!/usr/bin/env bash
# Shared env for ryvo_admin run/build scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MOBILE_ROOT="$(cd "$APP_ROOT/../.." && pwd)"
export APP_ROOT MOBILE_ROOT

# shellcheck source=../../scripts/mobile-env.sh
source "$MOBILE_ROOT/scripts/mobile-env.sh"

RYVO_APP=admin
export RYVO_APP

# Android SDK (optional for web-only runs)
if [[ -f "$SCRIPT_DIR/android-env.sh" ]]; then
  # shellcheck source=android-env.sh
  source "$SCRIPT_DIR/android-env.sh" || true
fi

: "${RYVO_FLUTTER_TARGET:=android}"
: "${RYVO_RELEASE_PLATFORM:=${RYVO_FLUTTER_TARGET}}"

apply_local_backend_urls() {
  if [[ "${RYVO_DEPLOY_TARGET}" != "local" ]]; then
    return
  fi
  case "$RYVO_FLUTTER_TARGET" in
    android)
      : "${SUPABASE_URL:=http://10.0.2.2:8400}"
      : "${FUNCTIONS_URL:=http://10.0.2.2:8400/functions/v1}"
      ;;
    ios)
      : "${SUPABASE_URL:=http://localhost:8400}"
      : "${FUNCTIONS_URL:=http://localhost:8400/functions/v1}"
      ;;
    *)
      : "${SUPABASE_URL:=http://localhost:8400}"
      : "${FUNCTIONS_URL:=http://localhost:8400/functions/v1}"
      ;;
  esac
}

if [[ "$RYVO_FLUTTER_TARGET" == "web" ]]; then
  : "${SUPABASE_URL:=http://localhost:8400}"
  : "${FUNCTIONS_URL:=http://localhost:8400/functions/v1}"
  : "${FLUTTER_DEVICE:=chrome}"
else
  apply_local_backend_urls
  : "${FLUTTER_DEVICE:=}"
fi

apply_package_id() {
  "$MOBILE_ROOT/scripts/set-package-id.sh" admin "${RYVO_DEPLOY_TARGET}"
}

prepare_android_signing() {
  local require="${1:-0}"
  if [[ "$require" == "1" ]]; then
    REQUIRE_ANDROID_SIGNING=1 "$MOBILE_ROOT/scripts/setup-android-signing.sh" \
      "${RYVO_DEPLOY_TARGET}" admin
  else
    "$MOBILE_ROOT/scripts/setup-android-signing.sh" "${RYVO_DEPLOY_TARGET}" admin
  fi
}

android_gradle_args() {
  echo "--"
  echo "-PdeployTarget=${RYVO_DEPLOY_TARGET}"
}

flutter_dart_defines() {
  "$MOBILE_ROOT/scripts/write-dart-defines.sh" "$APP_ROOT" "ryvo_admin" >/dev/null
  echo "--dart-define-from-file=${APP_ROOT}/dart_defines.json"
  # Repeat critical flags explicitly — some Flutter release builds skip file-only defines.
  echo "--dart-define=DEPLOY_TARGET=${RYVO_DEPLOY_TARGET}"
  echo "--dart-define=UPDATE_CHANNEL=${RYVO_UPDATE_CHANNEL}"
  echo "--dart-define=GITHUB_REPO=${GITHUB_REPO}"
  echo "--dart-define=APP_SLUG=ryvo_admin"
  echo "--dart-define=RELEASE_BRANCH=$(resolve_release_branch)"
  echo "--dart-define=RELEASE_PLATFORM=${RYVO_RELEASE_PLATFORM:-android}"
}

resolve_flutter_android_device() {
  if [[ -n "${FLUTTER_DEVICE:-}" ]]; then
    echo "$FLUTTER_DEVICE"
    return
  fi
  local id
  id="$(flutter devices 2>/dev/null | grep -E '• android' | head -1 | awk -F'•' '{gsub(/^ +| +$/,"",$2); print $2}' || true)"
  if [[ -z "$id" ]]; then
    echo "ERROR: No Android device/emulator found. Start an AVD or set FLUTTER_DEVICE=emulator-5554" >&2
    exit 1
  fi
  echo "$id"
}

resolve_flutter_ios_device() {
  if [[ -n "${FLUTTER_DEVICE:-}" ]]; then
    echo "$FLUTTER_DEVICE"
    return
  fi
  local id
  id="$(flutter devices 2>/dev/null | grep -Ei '• ios|• iphone|simulator' | head -1 | awk -F'•' '{gsub(/^ +| +$/,"",$2); print $2}' || true)"
  if [[ -z "$id" ]]; then
    echo "ERROR: No iOS simulator/device found. Open Xcode Simulator or set FLUTTER_DEVICE=<id>" >&2
    exit 1
  fi
  echo "$id"
}

resolve_flutter_device() {
  case "$RYVO_FLUTTER_TARGET" in
    ios) resolve_flutter_ios_device ;;
    *) resolve_flutter_android_device ;;
  esac
}

resolve_flutter_web_device() {
  if [[ -n "${FLUTTER_DEVICE:-}" ]]; then
    echo "$FLUTTER_DEVICE"
    return
  fi
  if [[ -z "${DISPLAY:-}" ]]; then
    echo "web-server"
    return
  fi
  if flutter devices 2>/dev/null | grep -q 'Chrome'; then
    echo "chrome"
    return
  fi
  echo "web-server"
}
