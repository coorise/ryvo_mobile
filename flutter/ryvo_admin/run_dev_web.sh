#!/usr/bin/env bash
# Run Ryvo admin Flutter app in Chrome (web). Usage: ./run_dev_web.sh [extra flutter run args]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

export RYVO_FLUTTER_TARGET=web

# shellcheck source=scripts/flutter-env.sh
source "$ROOT/scripts/flutter-env.sh"

DEVICE="$(resolve_flutter_web_device)"
mapfile -t DART_DEFINES < <(flutter_dart_defines)

echo "==> ryvo_admin web dev run"
echo "    device: $DEVICE"
echo "    supabase: $SUPABASE_URL"
echo "    app env: $APP_ENV"
if [[ "$DEVICE" == "web-server" ]]; then
  echo "    open: http://localhost:${WEB_PORT:-8080} (pass --web-port=7357 to fix port)"
fi
echo ""

flutter pub get

exec flutter run \
  -d "$DEVICE" \
  "${DART_DEFINES[@]}" \
  "$@"
