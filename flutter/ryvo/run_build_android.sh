#!/usr/bin/env bash
# Build Ryvo client Android APK.
# Usage: ./run_build_android.sh dev|release [--local|--dev|--prod]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MODE="${1:-}"
shift || true

if [[ "$MODE" != "dev" && "$MODE" != "release" ]]; then
  echo "Usage: $0 dev|release [--local|--dev|--prod]" >&2
  exit 1
fi

export RYVO_FLUTTER_TARGET=android
export RYVO_RELEASE_PLATFORM=android

# shellcheck source=scripts/flutter-env.sh
source "$ROOT/scripts/flutter-env.sh"
parse_run_flags "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local|--dev|--prod|--remote-updates|--no-remote-updates) shift ;;
    *) break ;;
  esac
done

apply_package_id
mapfile -t DART_DEFINES < <(flutter_dart_defines)

echo "==> ryvo client build ($MODE, android)"
echo "    deploy: $RYVO_DEPLOY_TARGET"
echo "    updates: $RYVO_UPDATE_CHANNEL"
echo "    package: $(resolve_package_id client)"
echo "    signing: android/.keys/${RYVO_DEPLOY_TARGET}/"
echo "    defines: ${APP_ROOT}/dart_defines.json"
echo ""

flutter pub get

if [[ "$MODE" == "dev" ]]; then
  flutter build apk --debug "${DART_DEFINES[@]}"
  echo ""
  echo "Done: $ROOT/build/app/outputs/flutter-apk/app-debug.apk"
else
  prepare_android_signing 1
  export RYVO_DEPLOY_TARGET
  flutter build apk --release "${DART_DEFINES[@]}"
  echo ""
  echo "Done: $ROOT/build/app/outputs/flutter-apk/app-release.apk"
fi
