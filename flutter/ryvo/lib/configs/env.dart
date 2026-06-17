class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://10.0.2.2:8400',
  );

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

  static const deployTarget = String.fromEnvironment(
    'DEPLOY_TARGET',
    defaultValue: 'local',
  );

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
    defaultValue: 'dev_client',
  );

  static const appSlug = String.fromEnvironment(
    'APP_SLUG',
    defaultValue: 'ryvo',
  );

  static bool get isDev => appEnv == 'development';
  static bool get isLocalDeploy => deployTarget == 'local';

  static bool get checkGithubReleases {
    if (deployTarget == 'local') return false;
    if (updateChannel == 'local') return false;
    return updateChannel == 'remote' || deployTarget == 'dev' || deployTarget == 'prod';
  }

  static String releaseTagPrefix() {
    if (deployTarget == 'prod') return '$appSlug-v';
    return '$appSlug-$deployTarget-v';
  }
}
