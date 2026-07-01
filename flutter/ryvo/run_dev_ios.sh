#!/usr/bin/env bash
# Run Ryvo client app on iOS simulator or device (hot reload). Requires macOS + Xcode.
# Usage: ./run_dev_ios.sh [--local|--dev|--prod] [--remote-updates|--no-remote-updates]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export RYVO_FLUTTER_TARGET=ios
export RYVO_RELEASE_PLATFORM=ios

# shellcheck source=scripts/flutter-env.sh
source "$ROOT/scripts/flutter-env.sh"
parse_run_flags "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local|--dev|--prod|--remote-updates|--no-remote-updates) shift ;;
    --) shift; break ;;
    *) break ;;
  esac
done

apply_package_id
mapfile -t DART_DEFINES < <(flutter_dart_defines)

cd "$ROOT"
flutter pub get
DEVICE="$(resolve_flutter_device)"

echo "==> ryvo client dev run (ios)"
echo "    device: ${FLUTTER_DEVICE:-$DEVICE}"
echo "    deploy: $RYVO_DEPLOY_TARGET"
echo "    package: $(resolve_package_id client)"
echo "    supabase: ${SUPABASE_URL:-from dart_defines.json}"
echo ""

export RYVO_DEPLOY_TARGET
exec flutter run \
  -d "${FLUTTER_DEVICE:-$DEVICE}" \
  "${DART_DEFINES[@]}" \
  "$@"
