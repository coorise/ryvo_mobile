#!/usr/bin/env bash
# Run Ryvo client app (driver/client) on Android.
# Usage: ./run_dev.sh [--local|--dev|--prod] [--remote-updates|--no-remote-updates]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_ROOT="$(cd "$ROOT/../.." && pwd)"

# shellcheck source=../../scripts/mobile-env.sh
source "$MOBILE_ROOT/scripts/mobile-env.sh"
parse_run_flags "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local|--dev|--prod|--remote-updates|--no-remote-updates) shift ;;
    --) shift; break ;;
    *) break ;;
  esac
done

"$MOBILE_ROOT/scripts/set-package-id.sh" client "${RYVO_DEPLOY_TARGET}"
DEFINES="$("$MOBILE_ROOT/scripts/write-dart-defines.sh" "$ROOT" "ryvo")"

cd "$ROOT"
flutter pub get
DEVICE="$(flutter devices 2>/dev/null | grep -E '• android' | head -1 | awk -F'•' '{gsub(/^ +| +$/,"",$2); print $2}')"
exec flutter run -d "${FLUTTER_DEVICE:-$DEVICE}" --dart-define-from-file="$ROOT/dart_defines.json" "$@"
