#!/usr/bin/env bash
# Build Ryvo admin iOS app. Requires macOS + Xcode.
# Usage: ./run_build_ios.sh dev|release [--local|--dev|--prod]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MODE="${1:-}"
shift || true

if [[ "$MODE" != "dev" && "$MODE" != "release" ]]; then
  echo "Usage: $0 dev|release [--local|--dev|--prod]" >&2
  exit 1
fi

export RYVO_FLUTTER_TARGET=ios
export RYVO_RELEASE_PLATFORM=ios

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

echo "==> ryvo_admin build ($MODE, ios)"
echo "    deploy: $RYVO_DEPLOY_TARGET"
echo "    updates: $RYVO_UPDATE_CHANNEL"
echo "    package: $(resolve_package_id admin)"
echo "    defines: ${APP_ROOT}/dart_defines.json"
echo ""

flutter pub get

if [[ "$MODE" == "dev" ]]; then
  flutter build ios --simulator --debug --no-codesign "${DART_DEFINES[@]}"
  echo ""
  echo "Done: $ROOT/build/ios/iphonesimulator/Runner.app"
else
  flutter build ios --release --no-codesign "${DART_DEFINES[@]}"
  echo ""
  echo "Done: $ROOT/build/ios/iphoneos/Runner.app"
  echo "Tip: CI packages this as an unsigned .ipa — see scripts/ci-build-release.sh"
fi
