#!/usr/bin/env bash
# Run Ryvo admin on Android (hot reload).
# Usage: ./run_dev.sh [--local|--dev|--prod] [--remote-updates|--no-remote-updates] [flutter run args…]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

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
DEVICE="$(resolve_flutter_device)"
mapfile -t DART_DEFINES < <(flutter_dart_defines)

echo "==> ryvo_admin dev run"
echo "    device: $DEVICE"
echo "    deploy: $RYVO_DEPLOY_TARGET"
echo "    updates: $RYVO_UPDATE_CHANNEL"
echo "    package: $(resolve_package_id admin)"
echo "    supabase: ${SUPABASE_URL:-from dart_defines.json}"
echo "    defines: ${APP_ROOT}/dart_defines.json"
echo ""

flutter pub get

exec flutter run \
  -d "$DEVICE" \
  "${DART_DEFINES[@]}" \
  "$@"
