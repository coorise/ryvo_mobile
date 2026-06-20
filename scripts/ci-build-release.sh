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
APPETIZE_BUNDLE_NAME=""
if [[ "$PLATFORM" == "ios" ]]; then
  APPETIZE_BUNDLE_NAME="$(resolve_release_appetize_bundle_name "$APP_SLUG" "$TARGET" "$PLATFORM")"
fi
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
    RELEASE_BRANCH="$(resolve_release_branch)"
    EXTRA_DEFINES=(
      "--dart-define-from-file=${APP_DIR}/dart_defines.json"
      "--dart-define=RELEASE_PLATFORM=ios"
      "--dart-define=DEPLOY_TARGET=${RYVO_DEPLOY_TARGET}"
      "--dart-define=UPDATE_CHANNEL=${RYVO_UPDATE_CHANNEL}"
      "--dart-define=GITHUB_REPO=${GITHUB_REPO}"
      "--dart-define=APP_SLUG=${APP_SLUG}"
      "--dart-define=RELEASE_BRANCH=${RELEASE_BRANCH}"
    )

    # Device build → IPA (Payload/Runner.app) for sideload / OTA.
    (
      cd "$APP_DIR"
      flutter pub get
      flutter build ios --release --no-codesign "${EXTRA_DEFINES[@]}"
    )
    RUNNER_APP="$APP_DIR/build/ios/iphoneos/Runner.app"
    if [[ ! -d "$RUNNER_APP" ]]; then
      echo "ERROR: iOS device app not found at $RUNNER_APP" >&2
      exit 1
    fi

    RAW="$(grep '^version:' "$APP_DIR/pubspec.yaml" | awk '{print $2}')"
    VERSION_NAME="${RAW%%+*}"
    BUILD_NUMBER="${RAW#*+}"
    BUNDLE_ID="$(resolve_package_id "$APP")"

    patch_ios_app_plist() {
      local app_path="$1"
      local plist="$app_path/Info.plist"
      [[ -f "$plist" ]] || return 0
      /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NAME" "$plist" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION_NAME" "$plist"
      /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$plist" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$plist"
      /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$plist" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$plist"
    }

    patch_ios_app_plist "$RUNNER_APP"

    mkdir -p "$STAGE_DIR"

    IPA_DIR="$(mktemp -d)"
    mkdir -p "$IPA_DIR/Payload"
    cp -R "$RUNNER_APP" "$IPA_DIR/Payload/"
    (
      cd "$IPA_DIR"
      zip -qr "$STAGE_DIR/$ARTIFACT_NAME" Payload
    )
    rm -rf "$IPA_DIR"

    # Simulator build → .zip with Runner.app at root for Appetize.io cloud emulators.
    (
      cd "$APP_DIR"
      flutter build ios --release --simulator --no-codesign "${EXTRA_DEFINES[@]}"
    )
    SIM_APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"
    if [[ ! -d "$SIM_APP" ]]; then
      echo "ERROR: iOS simulator app not found at $SIM_APP" >&2
      exit 1
    fi
    patch_ios_app_plist "$SIM_APP"

    APPETIZE_DIR="$(mktemp -d)"
    cp -R "$SIM_APP" "$APPETIZE_DIR/Runner.app"
    (
      cd "$APPETIZE_DIR"
      zip -qr "$STAGE_DIR/$APPETIZE_BUNDLE_NAME" Runner.app
    )
    rm -rf "$APPETIZE_DIR"

    echo "==> Appetize bundle: $APPETIZE_BUNDLE_NAME (simulator Runner.app at zip root)"
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
    if [[ -n "$APPETIZE_BUNDLE_NAME" ]]; then
      echo "appetize_bundle_name=$APPETIZE_BUNDLE_NAME"
    fi
  } >>"$GITHUB_OUTPUT"
fi

echo "==> staged $ARTIFACT_NAME (tag: $TAG, version: $RAW, branch: $RELEASE_BRANCH)"
if [[ -n "$APPETIZE_BUNDLE_NAME" ]]; then
  echo "==> staged $APPETIZE_BUNDLE_NAME for Appetize.io"
fi
