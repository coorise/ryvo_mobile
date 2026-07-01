# Ryvo-Line Client (Flutter)

Mobile app for Ryvo-Line **drivers** and **riders**. Architecture mirrors [`client/web/ryvo`](../../web/ryvo).

## Package

- **Dart package:** `ryvo`
- **Android application ID:** `com.ryvo.client` (`.local` / `.dev` suffixes for non-prod)

## Prerequisites

1. **Flutter** 3.41+ (`flutter doctor`)
2. **Android:** Android SDK at `~/Android/Sdk` (emulator or device)
3. **iOS:** macOS with **Xcode 15+** and an iOS Simulator or device
4. **Local backend:** sibling [Ryvo server](https://github.com/coorise/ryvo) checkout with Supabase on port `8400`

### Script permissions (macOS / Linux)

Helper scripts must be executable once after clone:

```bash
chmod +x run_dev_android.sh run_dev_ios.sh run_build_android.sh run_build_ios.sh
```

## Configure Supabase (local)

`ANON_KEY` is read from `server/supabase/.env` when present. Local backend URLs differ by platform:

| Platform | Host URL (from app) |
|----------|---------------------|
| Android emulator | `http://10.0.2.2:8400` |
| iOS Simulator | `http://localhost:8400` |

## Run locally

From this directory (`flutter/ryvo`):

### Android

```bash
./run_dev_android.sh                  # local Supabase, no OTA checks
./run_dev_android.sh --dev            # dev backend + remote release checks
export FLUTTER_DEVICE=emulator-5554   # optional override
./run_dev_android.sh
```

### iOS (macOS only)

```bash
./run_dev_ios.sh                      # local Supabase @ localhost:8400
open -a Simulator                     # if no simulator is booted
export FLUTTER_DEVICE=<simulator-id>  # optional: flutter devices
./run_dev_ios.sh
```

## Build locally

```bash
./run_build_android.sh dev            # debug APK
./run_build_android.sh release --prod # signed release APK

./run_build_ios.sh dev              # simulator debug .app
./run_build_ios.sh release --dev    # unsigned device build (see CI for .ipa)
```

## Test credentials

- Driver: `driver@ryvo-line.com` / `Driver@123`
- Client: `client@ryvo-line.com` / `Client@123`

## Troubleshooting

**No Android emulator:** start one in Android Studio or `flutter emulators --launch <id>`.

**No iOS simulator:** `open -a Simulator` or pick a device in Xcode.

**Login fails:** ensure local Supabase is running and you used the platform script (`run_dev_android.sh` vs `run_dev_ios.sh`) so the correct host URL is set.

**Supabase not configured:** run via `./run_dev_android.sh` or `./run_dev_ios.sh` — they load `dart_defines.json` automatically.

More on branches, OTA releases, and CI: [`client/mobile/README.md`](../../README.md).
