#!/usr/bin/env bash
# CI: build release artifact and stage it for GitHub Releases.
# Usage: ci-build-release.sh <admin|client> <dev|prod> <android|ios>
set -euo pipefail

APP="${1:?usage: ci-build-release.sh admin|client dev|prod android|ios}"
TARGET="${2:?usage: ci-build-release.sh admin|client dev|prod android|ios}"
PLATFORM="${3:?usage: ci-build-release.sh admin|client dev|prod android|ios}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=mobile-env.sh
source "$SCRIPT_DIR/mobile-env.sh"

export RYVO_APP="$APP"
export RYVO_DEPLOY_TARGET="$TARGET"
export RYVO_RELEASE_PLATFORM="$PLATFORM"
export RYVO_UPDATE_CHANNEL="${RYVO_UPDATE_CHANNEL:-remote}"

APP_SLUG="$(resolve_app_slug "$APP")"
APP_DIR="$(app_flutter_dir "$APP")"
ARTIFACT_NAME="$(resolve_release_artifact_name "$APP_SLUG" "$TARGET" "$PLATFORM")"
STAGE_DIR="$MOBILE_ROOT/.github_releases/mobile/$PLATFORM"

chmod +x "$SCRIPT_DIR"/*.sh "$APP_DIR"/*.sh "$APP_DIR"/scripts/*.sh 2>/dev/null || true
"$SCRIPT_DIR/set-package-id.sh" "$APP" "$TARGET"
"$SCRIPT_DIR/write-dart-defines.sh" "$APP_DIR" "$APP_SLUG" >/dev/null

case "$PLATFORM" in
  android)
    REQUIRE_ANDROID_SIGNING=1 "$SCRIPT_DIR/setup-android-signing.sh" "$TARGET" "$APP"
    (
      cd "$APP_DIR"
      ./run_build.sh release "--$TARGET"
    )
    mkdir -p "$STAGE_DIR"
    cp "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" \
      "$STAGE_DIR/$ARTIFACT_NAME"
    ;;
  ios)
    (
      cd "$APP_DIR"
      flutter pub get
      mapfile -t EXTRA_DEFINES < <(
        echo "--dart-define-from-file=${APP_DIR}/dart_defines.json"
        echo "--dart-define=RELEASE_PLATFORM=ios"
        echo "--dart-define=DEPLOY_TARGET=${RYVO_DEPLOY_TARGET}"
        echo "--dart-define=UPDATE_CHANNEL=${RYVO_UPDATE_CHANNEL}"
        echo "--dart-define=GITHUB_REPO=${GITHUB_REPO}"
        echo "--dart-define=APP_SLUG=${APP_SLUG}"
        echo "--dart-define=RELEASE_BRANCH=$(resolve_release_branch)"
      )
      flutter build ipa --release --no-codesign "${EXTRA_DEFINES[@]}"
    )
    IPA_SRC="$(find "$APP_DIR/build/ios/ipa" -maxdepth 1 -name '*.ipa' -print -quit)"
    if [[ -z "$IPA_SRC" || ! -f "$IPA_SRC" ]]; then
      echo "ERROR: iOS IPA not found under $APP_DIR/build/ios/ipa" >&2
      exit 1
    fi
    mkdir -p "$STAGE_DIR"
    cp "$IPA_SRC" "$STAGE_DIR/$ARTIFACT_NAME"
    ;;
  *)
    echo "ERROR: unknown platform: $PLATFORM" >&2
    exit 1
    ;;
esac

RAW="$(grep '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}')"
TAG="$(resolve_release_tag "$APP_SLUG" "$TARGET" "$PLATFORM" "$RAW")"
RELEASE_BRANCH="$(resolve_release_branch)"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "raw=$RAW"
    echo "tag=$TAG"
    echo "artifact_name=$ARTIFACT_NAME"
    echo "app_slug=$APP_SLUG"
    echo "platform=$PLATFORM"
    echo "release_branch=$RELEASE_BRANCH"
  } >>"$GITHUB_OUTPUT"
fi

echo "==> staged $ARTIFACT_NAME (tag: $TAG, version: $RAW, branch: $RELEASE_BRANCH)"
