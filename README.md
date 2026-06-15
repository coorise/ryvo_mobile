# Ryvo-Line Mobile

Separate repo for Flutter apps: **admin** (`flutter/ryvo_admin`) and **client** (`flutter/ryvo` — driver/client, WIP).

Remote: [github.com/coorise/ryvo_mobile](https://github.com/coorise/ryvo_mobile)

## Deploy targets & package IDs

| Target | Flag | Admin package | Client package | GitHub releases |
|--------|------|---------------|----------------|-----------------|
| **Local** | `--local` (default) | `com.ryvo.admin.local` | `com.ryvo.client.local` | Off |
| **Dev** | `--dev` | `com.ryvo.admin.dev` | `com.ryvo.client.dev` | Branch `dev` |
| **Prod** | `--prod` | `com.ryvo.admin` | `com.ryvo.client` | Branch `main` |

Package IDs are applied with [change_app_package_name](https://pub.dev/packages/change_app_package_name):

```bash
./scripts/set-package-id.sh admin local   # or dev | prod
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

**Optional (not set yet):** iOS signing (`IOS_*`), Play Store upload (`ANDROID_*`), `GITHUB_TOKEN` is provided by Actions for releases.

Release tags: `ryvo_admin-dev-v1.0.0+1` (dev), `ryvo_admin-v1.0.0+1` (prod).

## Branches

- `dev` — dev APKs + `*.dev` package IDs
- `main` — production APKs + production package IDs
