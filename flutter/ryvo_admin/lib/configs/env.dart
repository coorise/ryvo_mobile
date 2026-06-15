/// Runtime configuration — pass via `--dart-define` / `dart_defines.json` (see README).
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://10.0.2.2:8400',
  );

  /// Local demo key — same as `client/web/ryvo_admin/.env.example` and local Supabase stack.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );

  static const functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_URL',
    defaultValue: 'http://10.0.2.2:8400/functions/v1',
  );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// local | dev | prod
  static const deployTarget = String.fromEnvironment(
    'DEPLOY_TARGET',
    defaultValue: 'local',
  );

  /// local = skip GitHub release checks; remote = prompt on home/landing.
  static const updateChannel = String.fromEnvironment(
    'UPDATE_CHANNEL',
    defaultValue: 'local',
  );

  static const githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'coorise/ryvo_mobile',
  );

  static const releaseBranch = String.fromEnvironment(
    'RELEASE_BRANCH',
    defaultValue: 'dev',
  );

  static const appSlug = String.fromEnvironment(
    'APP_SLUG',
    defaultValue: 'ryvo_admin',
  );

  static bool get isDev => appEnv == 'development';
  static bool get isLocalDeploy => deployTarget == 'local';
  static bool get checkGithubReleases => updateChannel == 'remote';

  /// Release tag prefix, e.g. ryvo_admin-dev-v1.0.0+2
  static String releaseTagPrefix() {
    if (deployTarget == 'prod') return '${appSlug}-v';
    return '$appSlug-$deployTarget-v';
  }
}
