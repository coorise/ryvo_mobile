# Ryvo-Line Admin (Flutter)

Mobile admin app for Ryvo-Line staff. Architecture mirrors [`client/web/ryvo_admin/src`](../../web/ryvo_admin/src) so web and mobile stay aligned.

## Package

- **Dart package:** `ryvo_admin`
- **Android application ID:** `com.ryvo.admin`

## Folder layout (`lib/`)

Same top-level folders as the web admin `src/` tree:

```
lib/
├── app/           # screens (auth, admin, landing, search, splash, layout, router)
├── components/    # UI widgets (admin, auth, layout, ryvo, …)
├── configs/       # env.dart, const.dart
├── core/          # shared core helpers
├── guards/        # ABAC / route guards
├── hooks/         # useAuth and other hooks (Riverpod wrappers)
├── i18n/locales/  # JSON locales (copied from web)
├── lib/           # utilities (api_client — mirrors web src/lib)
├── services/      # Supabase + API services
├── stores/        # Riverpod state (mirrors web Zustand stores)
└── types/         # schemas / interfaces
```

Regenerate empty scaffold folders from web:

```bash
bash scripts/sync-lib-structure.sh
```

## UI

Uses [shadcn_ui](https://pub.dev/packages/shadcn_ui) (Flutter port of shadcn/ui) with Ryvo green theme (`ShadGreenColorScheme`).

## Prerequisites

1. **Flutter** 3.41+ (`flutter doctor` should pass)
2. **Android SDK** at `~/Android/Sdk`

### Android SDK / `flutter doctor`

If `cmdline-tools` was missing, install and accept licenses:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
flutter config --android-sdk "$ANDROID_HOME"
yes | flutter doctor --android-licenses
flutter doctor
```

Add to `~/.bashrc` or `~/.profile`:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## Configure Supabase

Copy `ANON_KEY` from `server/supabase/.env` and run with `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://10.0.2.2:8400 \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=FUNCTIONS_URL=http://10.0.2.2:8400/functions/v1
```

Use `10.0.2.2` for the Android emulator to reach the host machine's `localhost:8400`.

## Run

### Helper scripts (recommended)

From this directory:

```bash
# Dev: hot reload on the first Android emulator/device
./run_dev.sh

# Dev: web (Chrome when DISPLAY is set, otherwise web-server)
./run_dev_web.sh --web-port=7357
# Then open http://localhost:7357

# Build APK (reads ANON_KEY from server/supabase/.env automatically)
./run_build.sh dev      # debug APK
./run_build.sh release  # release APK

# Regenerate launcher icons after changing assets/icons/app_icon.png
dart run flutter_launcher_icons
```

Optional overrides:

```bash
export FLUTTER_DEVICE=emulator-5554
export SUPABASE_URL=http://10.0.2.2:8400
./run_dev.sh
```

### Manual flutter run

```bash
flutter pub get
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=http://10.0.2.2:8400 \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=FUNCTIONS_URL=http://10.0.2.2:8400/functions/v1
```

### Troubleshooting

**NDK install failed (corrupt zip on first build):**

```bash
source scripts/android-env.sh
rm -rf "$ANDROID_HOME/ndk/28.2.13676358" "$ANDROID_HOME/.temp/"*
yes | sdkmanager --install "ndk;28.2.13676358"
```

**No emulator:** start one in Android Studio, or `flutter emulators --launch <id>`.

**Login fails / loops back to sign-in:** ensure local Supabase is running and `./run_dev.sh` loads `ANON_KEY` from `server/supabase/.env`. Admin roles come from the JWT + `/v1/admin/rbac/me` enrichment (same as web).

**Web on headless Linux:** `./run_dev_web.sh` uses `web-server` automatically; open the printed URL in a browser.

## Test credentials

- Admin: `admin@ryvo-line.com` / `Admin@123`

## Next steps (porting from web)

1. Map each `src/app/admin/**/page.tsx` → `lib/app/admin/**/` Dart screen
2. Port services from `src/services/*.ts` → `lib/services/`
3. Port guards/hooks from `src/guards` and `src/hooks`
4. Reuse i18n keys from `lib/i18n/locales/en.json`
