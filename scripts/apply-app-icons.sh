#!/usr/bin/env bash
# Generate launcher icons with optional LOCAL/DEV badge for non-prod builds.
# Usage: ./scripts/apply-app-icons.sh admin|client [local|dev|prod]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=mobile-env.sh
source "$ROOT/scripts/mobile-env.sh"

APP="${1:-}"
TARGET="${2:-${RYVO_DEPLOY_TARGET}}"

if [[ "$APP" != "admin" && "$APP" != "client" ]]; then
  echo "Usage: $0 admin|client [local|dev|prod]" >&2
  exit 1
fi

RYVO_DEPLOY_TARGET="$TARGET"
export RYVO_DEPLOY_TARGET

APP_DIR="$(app_flutter_dir "$APP")"
BASE_ICON="$APP_DIR/assets/icons/app_icon.png"
GEN_DIR="$APP_DIR/assets/icons/.generated"
GEN_ICON="$GEN_DIR/app_icon_${TARGET}.png"
ICON_CONFIG="$APP_DIR/flutter_launcher_icons.generated.yaml"

if [[ ! -f "$BASE_ICON" ]]; then
  echo "ERROR: missing base icon: $BASE_ICON" >&2
  exit 1
fi

echo "==> apply-app-icons"
echo "    app: $APP"
echo "    target: $RYVO_DEPLOY_TARGET"
echo ""

python3 "$ROOT/scripts/generate-badged-icon.py" "$RYVO_DEPLOY_TARGET" "$BASE_ICON" "$GEN_ICON"

cat > "$ICON_CONFIG" <<EOF
flutter_launcher_icons:
  android: true
  ios: true
  image_path: ${GEN_ICON#"$APP_DIR/"}
  adaptive_icon_background: "#15803d"
  adaptive_icon_foreground: ${GEN_ICON#"$APP_DIR/"}
  web:
    generate: true
    image_path: ${GEN_ICON#"$APP_DIR/"}
    background_color: "#15803d"
    theme_color: "#15803d"
EOF

cd "$APP_DIR"
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.generated.yaml

echo "Done: icons for $RYVO_DEPLOY_TARGET ($GEN_ICON)"
