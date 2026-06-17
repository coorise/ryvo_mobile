# Ryvo-Line Mobile

Mobile apps for Ryvo-Line Server — separate repo for Flutter **admin** and **client** apps.

Remote: [github.com/coorise/ryvo_mobile](https://github.com/coorise/ryvo_mobile)

## Deploy targets & package IDs

| Target | Flag | Admin package | Client package | Release branch |
|--------|------|---------------|----------------|----------------|
| **Local** | `--local` (default) | `com.ryvo.admin.local` | `com.ryvo.client.local` | Off |
| **Dev** | `--dev` | `com.ryvo.admin.dev` | `com.ryvo.client.dev` | `dev_admin` / `dev_client` |
| **Prod** | `--prod` | `com.ryvo.admin` | `com.ryvo.client` | `main_admin` / `main_client` |

Package IDs are applied with [change_app_package_name](https://pub.dev/packages/change_app_package_name). **Launcher icons** get a corner badge automatically:

| Target | Badge |
|--------|-------|
| `local` | blue **LOCAL** |
| `dev` | orange **DEV** |
| `prod` | none (base icon) |

```bash
./scripts/set-package-id.sh admin local   # or dev | prod (also refreshes icons)
./scripts/apply-app-icons.sh admin dev    # icons only
./scripts/set-package-id.sh client local
```

## Admin — local dev

Requires sibling [Ryvo server](https://github.com/coorise/ryvo) checkout (`../ryvo/server/supabase/.env`) or exported secrets.

```bash
cd flutter/ryvo_admin
./run_dev.sh                  # local Supabase @ 10.0.2.2:8400, no OTA checks
./run_dev.sh --dev            # dev backend + remote release checks
./run_build.sh release --prod
```

### Update channel

- **Local** (`--local` or default): no GitHub release check on launch.
- **Remote** (`--dev` / `--prod`, or `--remote-updates`): on launch, app checks [GitHub releases](https://github.com/coorise/ryvo_mobile/releases) for a newer APK and prompts to download/install.

Ignored release tags are stored in app preferences until a newer tag appears.

## CI secrets (GitHub Actions)

Configured in repo **Settings → Secrets**:

| Secret | Used on |
|--------|---------|
| `DEV_SUPABASE_URL` | `dev_admin`, `dev_client` builds |
| `DEV_SUPABASE_ANON_KEY` | dev release branches |
| `DEV_SUPABASE_FUNCTIONS_URL` | dev release branches |
| `DEV_GOOGLE_MAPS_API_KEY` | dev release branches |
| `PROD_SUPABASE_URL` | `main_admin`, `main_client` builds |
| `PROD_SUPABASE_ANON_KEY` | prod release branches |
| `PROD_SUPABASE_FUNCTIONS_URL` | prod release branches |
| `PROD_GOOGLE_MAPS_API_KEY` | prod release branches |
| `ADMIN_DEV_ANDROID_KEYSTORE_BASE64` | `dev_admin` workflow |
| `ADMIN_DEV_ANDROID_KEYSTORE_PASSWORD` | `dev_admin` |
| `ADMIN_DEV_ANDROID_KEY_PASSWORD` | `dev_admin` |
| `ADMIN_DEV_ANDROID_KEY_ALIAS` | `dev_admin` |
| `ADMIN_PROD_ANDROID_KEYSTORE_BASE64` | `main_admin` workflow |
| `ADMIN_PROD_ANDROID_KEYSTORE_PASSWORD` | `main_admin` |
| `ADMIN_PROD_ANDROID_KEY_PASSWORD` | `main_admin` |
| `ADMIN_PROD_ANDROID_KEY_ALIAS` | `main_admin` |
| `DEV_ANDROID_KEYSTORE_BASE64` | `dev_client` workflow |
| `DEV_ANDROID_KEYSTORE_PASSWORD` | `dev_client` |
| `DEV_ANDROID_KEY_PASSWORD` | `dev_client` |
| `DEV_ANDROID_KEY_ALIAS` | `dev_client` |
| `PROD_ANDROID_KEYSTORE_BASE64` | `main_client` workflow |
| `PROD_ANDROID_KEYSTORE_PASSWORD` | `main_client` |
| `PROD_ANDROID_KEY_PASSWORD` | `main_client` |
| `PROD_ANDROID_KEY_ALIAS` | `main_client` |

**Optional (not set yet):** iOS signing (`IOS_*`), Play Store upload. `GITHUB_TOKEN` is provided by Actions for releases.

### Android release signing

Keystores live under `flutter/<app>/android/.keys/<local|dev|prod>/` (gitignored):

| App | Path | GitHub secret prefix |
|-----|------|----------------------|
| admin | `flutter/ryvo_admin/android/.keys/` | `ADMIN_DEV_ANDROID_*` / `ADMIN_PROD_ANDROID_*` |
| client | `flutter/ryvo/android/.keys/` | `DEV_ANDROID_*` / `PROD_ANDROID_*` |

Each folder needs `upload-keystore.jks` + `key.properties` (see `android/key.properties.example`).

```bash
# One command per app + target (interactive password prompt)
./scripts/generate-android-keystore.sh admin local
./scripts/generate-android-keystore.sh admin dev
./scripts/generate-android-keystore.sh admin prod
./scripts/generate-android-keystore.sh client dev
./scripts/generate-android-keystore.sh client prod
./scripts/generate-android-keystore.sh client local

# Non-interactive (optional)
ANDROID_KEYSTORE_PASSWORD='…' ./scripts/generate-android-keystore.sh admin dev

# Base64 for GitHub (admin dev example)
base64 -w 0 flutter/ryvo_admin/android/.keys/dev/upload-keystore.jks
```

`./run_build.sh release --dev` reads `android/.keys/dev/`; CI decodes the same layout from secrets before building.

Release tags:

| App | Dev tag | Prod tag |
|-----|---------|----------|
| admin | `ryvo_admin-dev-v1.0.0-1` | `ryvo_admin-v1.0.0-1` |
| client | `ryvo-dev-v1.0.0-1` | `ryvo-v1.0.0-1` |

## Branches

| Branch | Purpose | CI workflow |
|--------|---------|-------------|
| `dev` | Integration branch — commit and push here; **does not** trigger releases | — |
| `main` | Stable snapshot for cloning; **does not** trigger releases | — |
| `dev_admin` | Admin dev OTA releases | `build_dev_admin.yml` |
| `main_admin` | Admin production OTA releases | `build_main_admin.yml` |
| `dev_client` | Client/driver dev OTA releases | `build_dev.yml` |
| `main_client` | Client/driver production OTA releases | `build_main.yml` |

**Release flow:** merge `dev` → `dev_admin` / `dev_client` / `main_admin` / `main_client` when you want to publish an OTA build for that app and environment.
