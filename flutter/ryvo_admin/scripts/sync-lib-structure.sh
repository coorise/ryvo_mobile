#!/usr/bin/env bash
# Mirror client/web/ryvo_admin/src folder tree under lib/ (Flutter admin app).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_SRC="$ROOT/../../../web/ryvo_admin/src"
LIB="$ROOT/lib"

mkdir -p "$LIB"

copy_tree() {
  local rel="$1"
  local src="$WEB_SRC/$rel"
  local dst="$LIB/$rel"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    find "$src" -type d | while read -r dir; do
      local sub="${dir#$src/}"
      [[ -z "$sub" ]] && continue
      mkdir -p "$dst/$sub"
      [[ -f "$dst/$sub/.gitkeep" ]] || touch "$dst/$sub/.gitkeep"
    done
  fi
}

for top in app components configs core guards hooks i18n services stores types; do
  copy_tree "$top"
done

# Web utilities live in src/lib → lib/lib (per draft-instructions.txt)
copy_tree "lib"

# Draft extras not yet on web
mkdir -p "$LIB/app/search"
touch "$LIB/app/search/.gitkeep"

# Assets + barrel stubs
mkdir -p "$ROOT/assets/images"
touch "$ROOT/assets/images/.gitkeep"

for dir in components configs core guards hooks services stores types lib; do
  idx="$LIB/$dir/index.dart"
  if [[ ! -f "$idx" ]]; then
    echo "// Barrel exports for $dir — add exports as modules are ported from web." >"$idx"
  fi
done

echo "Synced lib/ structure from $WEB_SRC"
