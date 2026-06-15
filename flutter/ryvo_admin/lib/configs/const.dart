/// Mirrors `client/web/ryvo_admin/src/configs/const.ts` (subset — extend as features port).
class AppConst {
  AppConst._();

  static const appName = 'Ryvo-Line';
  static const appTagline = 'Ride smarter — OTA test build';
  static const packageId = 'com.ryvo.admin';

  static const supportedLanguages = ['en', 'fr', 'es', 'zh', 'de'];

  static const storageAuth = 'ryvo.admin.auth.v1';
  static const storageTheme = 'ryvo.admin.theme';
  static const storageLanguage = 'ryvo.admin.lang';
  static const storageNavExpanded = 'ryvo.admin.nav.expanded.v1';
  static const storagePasswordReset = 'ryvo.password-reset.v1';
  static const storageIgnoredRelease = 'ryvo.admin.ignored_release.v1';
}

class Routes {
  Routes._();

  static const landing = '/landing';
  static const splash = '/';

  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authVerifyEmail = '/auth/verify-email';
  static const authForgotPassword = '/auth/forgot-password';
  static const authOtp = '/auth/otp';
  static const authResetPassword = '/auth/reset-password';

  static const adminHome = '/admin';
  static const adminMap = '/admin/map';
  static const adminRides = '/admin/rides';
  static const adminUsersList = '/admin/users';
  static const adminUsersNew = '/admin/users/new';
  static const adminUsersProfile = '/admin/users/profile';
  static const adminStaffList = '/admin/staff';
  static const adminStaffNew = '/admin/staff/new';
  static const adminStaffAssign = '/admin/staff/assign';
  static const adminStaffProfile = '/admin/staff/profile';
  static const adminDriversList = '/admin/drivers';
  static const adminDriversNew = '/admin/drivers/new';
  static const adminDriversProfile = '/admin/drivers/profile';
  static const adminTickets = '/admin/tickets';
  static const adminCommNotifications = '/admin/communication/notifications';
  static const adminCommMessages = '/admin/communication/messages';
  static const adminCommMessagesNew = '/admin/communication/messages/new';
  static const adminChatSupport = '/admin/communication/chat-support';
  static const adminHrFeedbacks = '/admin/hr/feedbacks';
  static const adminPayments = '/admin/payments';
  static const adminSecurity = '/admin/security';
  static const adminAudit = '/admin/audit';
  static const adminSettings = '/admin/settings';
  static const adminSettingsProfile = '/admin/settings/profile';
  static const adminSettingsConfigurations = '/admin/settings/configurations';
  static const adminSettingsTasks = '/admin/settings/tasks';
  static const adminObservability = '/admin/observability';
  static const adminFinanceReferrals = '/admin/finance/referrals';
  static const adminFinanceTariffs = '/admin/finance/tariffs';
  static const adminFinanceCheckouts = '/admin/finance/checkouts';
  static const adminFinancePaychecks = '/admin/finance/paychecks';
  static const adminFinanceSpeculative = '/admin/finance/speculative';
  static const adminAnalytics = '/admin/analytics';
  static const search = '/search';

  static const legalTos = '/legal/tos';
  static const legalPrivacy = '/legal/privacy';
}
