#!/usr/bin/env bash
# Apply Android/iOS bundle id for admin or client app.
# Usage: ./scripts/set-package-id.sh admin|client [local|dev|prod]
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

PKG="$(resolve_package_id "$APP")"
DIR="$(app_flutter_dir "$APP")"

echo "==> set-package-id"
echo "    app: $APP"
echo "    target: $RYVO_DEPLOY_TARGET"
echo "    package: $PKG"
echo "    dir: $DIR"
echo ""

cd "$DIR"
flutter pub get
if ! grep -q 'applicationId = appId' "$DIR/android/app/build.gradle.kts" 2>/dev/null; then
  dart run change_app_package_name:main "$PKG"
fi

PBX="$DIR/ios/Runner.xcodeproj/project.pbxproj"
if [[ -f "$PBX" ]]; then
  sed -i.bak -E \
    "s/PRODUCT_BUNDLE_IDENTIFIER = com\\.ryvo\\.(admin|client)(\\.[A-Za-z0-9]+)*;/PRODUCT_BUNDLE_IDENTIFIER = ${PKG};/g" \
    "$PBX"
  sed -i.bak -E \
    "s/PRODUCT_BUNDLE_IDENTIFIER = com\\.ryvo\\.(admin|client)(\\.[A-Za-z0-9]+)*\\.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = ${PKG}.RunnerTests;/g" \
    "$PBX"
  rm -f "$PBX.bak"
fi

"$ROOT/scripts/apply-app-icons.sh" "$APP" "$TARGET"

echo "Done: $PKG"
