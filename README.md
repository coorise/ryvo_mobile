# Ryvo-Line Mobile

Separate repo for Flutter apps: **admin** (`flutter/ryvo_admin`) and **client** (`flutter/ryvo` — driver/client, WIP).

Remote: [github.com/coorise/ryvo_mobile](https://github.com/coorise/ryvo_mobile)

## Deploy targets & package IDs

| Target | Flag | Admin package | Client package | GitHub releases |
|--------|------|---------------|----------------|-----------------|
| **Local** | `--local` (default) | `com.ryvo.admin.local` | `com.ryvo.client.local` | Off |
| **Dev** | `--dev` | `com.ryvo.admin.dev` | `com.ryvo.client.dev` | Branch `dev` |
| **Prod** | `--prod` | `com.ryvo.admin` | `com.ryvo.client` | Branch `main` |

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
| `DEV_SUPABASE_URL` | `dev` branch builds |
| `DEV_SUPABASE_ANON_KEY` | `dev` |
| `DEV_SUPABASE_FUNCTIONS_URL` | `dev` |
| `DEV_GOOGLE_MAPS_API_KEY` | `dev` |
| `PROD_SUPABASE_URL` | `main` branch builds |
| `PROD_SUPABASE_ANON_KEY` | `main` |
| `PROD_SUPABASE_FUNCTIONS_URL` | `main` |
| `PROD_GOOGLE_MAPS_API_KEY` | `main` |
| `ADMIN_DEV_ANDROID_KEYSTORE_BASE64` | admin `dev` branch |
| `ADMIN_DEV_ANDROID_KEYSTORE_PASSWORD` | admin `dev` |
| `ADMIN_DEV_ANDROID_KEY_PASSWORD` | admin `dev` |
| `ADMIN_DEV_ANDROID_KEY_ALIAS` | admin `dev` |
| `ADMIN_PROD_ANDROID_KEYSTORE_BASE64` | admin `main` branch |
| `ADMIN_PROD_ANDROID_KEYSTORE_PASSWORD` | admin `main` |
| `ADMIN_PROD_ANDROID_KEY_PASSWORD` | admin `main` |
| `ADMIN_PROD_ANDROID_KEY_ALIAS` | admin `main` |
| `DEV_ANDROID_KEYSTORE_BASE64` | client `dev` branch (when enabled) |
| `DEV_ANDROID_KEYSTORE_PASSWORD` | client `dev` |
| `DEV_ANDROID_KEY_PASSWORD` | client `dev` |
| `DEV_ANDROID_KEY_ALIAS` | client `dev` |
| `PROD_ANDROID_KEYSTORE_BASE64` | client `main` branch (when enabled) |
| `PROD_ANDROID_KEYSTORE_PASSWORD` | client `main` |
| `PROD_ANDROID_KEY_PASSWORD` | client `main` |
| `PROD_ANDROID_KEY_ALIAS` | client `main` |

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

Release tags: `ryvo_admin-dev-v1.0.0+1` (dev), `ryvo_admin-v1.0.0+1` (prod).

## Branches

- `dev` — dev APKs + `*.dev` package IDs
- `main` — production APKs + production package IDs
