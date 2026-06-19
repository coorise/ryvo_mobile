#!/usr/bin/env bash
# Shared Ryvo mobile env: deploy target (local/dev/prod), update channel, package ids.
set -euo pipefail

MOBILE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MOBILE_ROOT

# local | dev | prod — controls Android/iOS applicationId suffix and Supabase endpoints in CI.
: "${RYVO_DEPLOY_TARGET:=local}"

# android | ios — release branch + OTA tag platform segment.
: "${RYVO_RELEASE_PLATFORM:=android}"

# local = never check GitHub releases; remote = prompt on app home/landing launch.
: "${RYVO_UPDATE_CHANNEL:=local}"

# Monorepo server checkout (optional). Override when ryvo server is elsewhere.
: "${RYVO_SERVER_ROOT:=$(cd "$MOBILE_ROOT/../.." 2>/dev/null && pwd)/server}"

# GitHub repo for OTA release assets.
: "${GITHUB_REPO:=coorise/ryvo_mobile}"

resolve_release_branch() {
  local app="${RYVO_APP:-client}"
  local platform="${RYVO_RELEASE_PLATFORM:-android}"
  local prefix="dev"
  if [[ "${RYVO_DEPLOY_TARGET}" == "prod" ]]; then
    prefix="main"
  fi
  case "${app}-${platform}" in
    admin-android) echo "${prefix}_android_admin" ;;
    admin-ios) echo "${prefix}_ios_admin" ;;
    client-android) echo "${prefix}_android" ;;
    client-ios) echo "${prefix}_ios" ;;
    *)
      echo "ERROR: unknown app/platform: ${app}-${platform}" >&2
      return 1
      ;;
  esac
}

resolve_release_artifact_name() {
  local app_slug="$1"
  local target="$2"
  local platform="$3"
  local ext="apk"
  if [[ "$platform" == "ios" ]]; then
    ext="ipa"
  fi
  if [[ "$target" == "prod" ]]; then
    echo "${app_slug}-${platform}.${ext}"
  else
    echo "${app_slug}-${platform}-${target}.${ext}"
  fi
}

resolve_release_tag() {
  local app_slug="$1"
  local target="$2"
  local platform="$3"
  local raw_version="$4"
  local tag_version
  tag_version="$(echo "$raw_version" | tr '+' '-')"
  if [[ "$target" == "prod" ]]; then
    echo "${app_slug}-${platform}-v${tag_version}"
  else
    echo "${app_slug}-${platform}-${target}-v${tag_version}"
  fi
}

resolve_package_id() {
  local app="$1"
  case "${app}-${RYVO_DEPLOY_TARGET}" in
    admin-local) echo "com.ryvo.admin.local" ;;
    admin-dev) echo "com.ryvo.admin.dev" ;;
    admin-prod) echo "com.ryvo.admin" ;;
    client-local) echo "com.ryvo.client.local" ;;
    client-dev) echo "com.ryvo.client.dev" ;;
    client-prod) echo "com.ryvo.client" ;;
    *)
      echo "ERROR: unknown app/target: ${app}-${RYVO_DEPLOY_TARGET}" >&2
      return 1
      ;;
  esac
}

resolve_app_slug() {
  local app="$1"
  case "$app" in
    admin) echo "ryvo_admin" ;;
    client) echo "ryvo" ;;
    *) echo "ERROR: unknown app: $app" >&2; return 1 ;;
  esac
}

app_flutter_dir() {
  local app="$1"
  case "$app" in
    admin) echo "$MOBILE_ROOT/flutter/ryvo_admin" ;;
    client) echo "$MOBILE_ROOT/flutter/ryvo" ;;
    *) echo "ERROR: unknown app: $app" >&2; return 1 ;;
  esac
}

# Map deploy target → Supabase env prefix for GitHub Actions secrets (DEV_* / PROD_*).
resolve_supabase_secret_prefix() {
  case "${RYVO_DEPLOY_TARGET}" in
    prod) echo "PROD" ;;
    dev) echo "DEV" ;;
    local) echo "DEV" ;;
    *) echo "DEV" ;;
  esac
}

# GitHub Actions secret prefix for Android release signing (without _KEYSTORE_* suffix).
resolve_android_signing_secret_prefix() {
  local app="$1"
  local target="$2"
  case "${app}-${target}" in
    admin-dev) echo "ADMIN_DEV_ANDROID" ;;
    admin-prod) echo "ADMIN_PROD_ANDROID" ;;
    client-dev) echo "DEV_ANDROID" ;;
    client-prod) echo "PROD_ANDROID" ;;
    admin-local | client-local) echo "" ;;
    *)
      echo "ERROR: unknown app/target for signing: ${app}-${target}" >&2
      return 1
      ;;
  esac
}

parse_run_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)
        RYVO_DEPLOY_TARGET=local
        RYVO_UPDATE_CHANNEL=local
        ;;
      --dev)
        RYVO_DEPLOY_TARGET=dev
        RYVO_UPDATE_CHANNEL=remote
        ;;
      --prod)
        RYVO_DEPLOY_TARGET=prod
        RYVO_UPDATE_CHANNEL=remote
        ;;
      --remote-updates)
        RYVO_UPDATE_CHANNEL=remote
        ;;
      --no-remote-updates)
        RYVO_UPDATE_CHANNEL=local
        ;;
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
    shift
  done
  export RYVO_DEPLOY_TARGET RYVO_UPDATE_CHANNEL
}
