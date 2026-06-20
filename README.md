# Ryvo-Line Mobile

Mobile apps for Ryvo-Line Server — separate repo for Flutter **admin** and **client** apps.

Remote: [github.com/coorise/ryvo_mobile](https://github.com/coorise/ryvo_mobile)

## Deploy targets & package IDs

| Target | Flag | Admin package | Client package |
|--------|------|---------------|----------------|
| **Local** | `--local` (default) | `com.ryvo.admin.local` | `com.ryvo.client.local` |
| **Dev** | `--dev` | `com.ryvo.admin.dev` | `com.ryvo.client.dev` |
| **Prod** | `--prod` | `com.ryvo.admin` | `com.ryvo.client` |

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
- **Remote** (`--dev` / `--prod`, or `--remote-updates`): on launch, app checks [GitHub releases](https://github.com/coorise/ryvo_mobile/releases) for a newer **platform-specific** build (`.apk` on Android, `.ipa` on iOS) and prompts to download/install (Android in-app; iOS manual for now).

Ignored release tags are stored in app preferences until a newer tag appears.

## CI secrets (GitHub Actions)

Configured in repo **Settings → Secrets**:

| Secret | Used on |
|--------|---------|
| `DEV_SUPABASE_*` | `dev_*` release branches |
| `PROD_SUPABASE_*` | `main_*` release branches |
| `ADMIN_DEV_ANDROID_*` | `dev_android_admin` |
| `ADMIN_PROD_ANDROID_*` | `main_android_admin` |
| `DEV_ANDROID_*` | `dev_android` |
| `PROD_ANDROID_*` | `main_android` |

**iOS:** builds use `flutter build ipa --release --no-codesign` (unsigned IPA for manual install). Apple signing secrets are not required yet.

`GITHUB_TOKEN` is provided by Actions for releases.

### Android release signing

Keystores live under `flutter/<app>/android/.keys/<local|dev|prod>/` (gitignored).

```bash
./scripts/generate-android-keystore.sh admin dev
./scripts/generate-android-keystore.sh client prod
```

## Branches & workflows

| Branch | Purpose | Workflow |
|--------|---------|----------|
| `dev` | Integration — push daily work here | `build_dev.yml` (analyze + test) |
| `main` | Stable snapshot for cloning | `build_main.yml` (analyze + test) |
| `dev_android_admin` | Admin Android dev OTA | `build_dev_android_admin.yml` |
| `dev_ios_admin` | Admin iOS dev release | `build_dev_ios_admin.yml` |
| `main_android_admin` | Admin Android prod OTA | `build_main_android_admin.yml` |
| `main_ios_admin` | Admin iOS prod release | `build_main_ios_admin.yml` |
| `dev_android` | Client Android dev OTA | `build_dev_android.yml` |
| `dev_ios` | Client iOS dev release | `build_dev_ios.yml` |
| `main_android` | Client Android prod OTA | `build_main_android.yml` |
| `main_ios` | Client iOS prod release | `build_main_ios.yml` |

### Release tags

Tags include **app**, **platform**, and **environment**:

| App | Platform | Dev tag example | Prod tag example |
|-----|----------|-----------------|------------------|
| admin | Android | `ryvo_admin-android-dev-v1.0.2-8` | `ryvo_admin-android-v1.0.2-8` |
| admin | iOS | `ryvo_admin-ios-dev-v1.0.2-8` | `ryvo_admin-ios-v1.0.2-8` |
| client | Android | `ryvo-android-dev-v1.0.0-2` | `ryvo-android-v1.0.0-2` |
| client | iOS | `ryvo-ios-dev-v1.0.0-2` | `ryvo-ios-v1.0.0-2` |

Artifacts per iOS release (all four branches publish both):

| App | Env | Device (`.ipa`) | Simulator (`.zip` with `Runner.app` at root) |
|-----|-----|-----------------|------------------------------------------------|
| admin | dev | `ryvo_admin-ios-dev.ipa` | `ryvo_admin-ios-dev-simulator-app.zip` |
| admin | prod | `ryvo_admin-ios.ipa` | `ryvo_admin-ios-simulator-app.zip` |
| client | dev | `ryvo-ios-dev.ipa` | `ryvo-ios-dev-simulator-app.zip` |
| client | prod | `ryvo-ios.ipa` | `ryvo-ios-simulator-app.zip` |

**iOS assets (portable, platform-agnostic):**

- **`.ipa`** — device build (`Payload/Runner.app`). Use for sideload, signing pipelines, or physical-device OTA.
- **`*-simulator-app.zip`** — debug simulator `Runner.app` at the zip root. Use with any cloud emulator ([Appetize.io](https://appetize.io/), BrowserStack, etc.), or unzip and drag into Xcode Simulator.

Do not use GitHub’s auto-generated “Source code (zip)” — it contains no compiled `.app`.

### Release flow

```bash
cd client/mobile

# 1. Work on dev
git checkout dev
git push origin dev                    # runs integration CI only

# 2. Ship a platform build (merge dev or main as noted)
git push origin dev:dev_android_admin  # admin Android dev
git push origin dev:dev_ios_admin      # admin iOS dev
git push origin main:main_android_admin # admin Android prod (after merging dev → main)
git push origin main:main_ios_admin    # admin iOS prod

git push origin dev:dev_android        # client Android dev
git push origin dev:dev_ios            # client iOS dev
git push origin main:main_android      # client Android prod
git push origin main:main_ios          # client iOS prod

# 3. Keep main stable (integration CI only)
git checkout main && git merge dev && git push origin main
```

Bump `pubspec.yaml` version before re-pushing the same release branch (GitHub rejects duplicate tags).
