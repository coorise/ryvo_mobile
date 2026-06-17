class AppConst {
  AppConst._();

  static const appName = 'Ryvo-Line';
  static const appTagline = 'Ride smarter';
  static const packageId = 'com.ryvo.client';

  static const supportedLanguages = ['en', 'fr', 'es', 'zh', 'de'];

  static const storageAuth = 'ryvo.portal.auth.v1';
  static const storageTheme = 'ryvo.portal.theme';
  static const storageLanguage = 'ryvo.portal.lang';
  static const storageNavExpanded = 'ryvo.portal.nav.expanded.v1';
  static const storagePasswordReset = 'ryvo.password-reset.v1';
  static const storageIgnoredRelease = 'ryvo.portal.ignored_release.v1';
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

  static const driverHome = '/driver';
  static const driverLiveMap = '/driver/main/live-map';
  static const driverRides = '/driver/main/rides';
  static const driverClients = '/driver/main/clients';
  static const driverKyc = '/driver/main/kyc';
  static const driverKycCarsNew = '/driver/main/kyc/cars/new';
  static const driverKycCarDetail = '/driver/main/kyc/cars/detail';
  static const driverKycCarEdit = '/driver/main/kyc/cars/edit';
  static const driverNotifications = '/driver/communication/notifications';
  static const driverChat = '/driver/communication/chat';
  static const driverMessages = '/driver/communication/messages';
  static const driverChatSupport = '/driver/communication/chat-support';
  static const driverFeedbacks = '/driver/hr/feedbacks';
  static const driverPayments = '/driver/finances/payments';
  static const driverSecurityLogs = '/driver/audits/security-logs';
  static const driverActivityLogs = '/driver/audits/activity-logs';
  static const driverAnalytics = '/driver/audits/analytics';
  static const driverProfile = '/driver/settings/profile';
  static const driverConfigurations = '/driver/settings/configurations';
  static String driverRideDetail(String tripId) => '/driver/drive/$tripId';

  static const clientHome = '/client';
  static const clientLiveMap = '/client/main/live-map';
  static const clientRides = '/client/main/rides';
  static const clientDrivers = '/client/main/drivers';
  static const clientNotifications = '/client/communication/notifications';
  static const clientChat = '/client/communication/chat';
  static const clientChatSupport = '/client/communication/chat-support';
  static const clientFeedbacks = '/client/hr/feedbacks';
  static const clientPayments = '/client/finances/payments';
  static const clientSecurityLogs = '/client/audits/security-logs';
  static const clientActivityLogs = '/client/audits/activity-logs';
  static const clientAnalytics = '/client/audits/analytics';
  static const clientProfile = '/client/settings/profile';
  static const clientConfigurations = '/client/settings/configurations';
  static String clientRideDetail(String tripId) => '/client/drive/$tripId';

  static const legalTos = '/legal/tos';
  static const legalPrivacy = '/legal/privacy';
}

class PortalTabs {
  PortalTabs._();

  static const liveMapLive = 'live';
  static const liveMapIncoming = 'incoming';
  static const liveMapDriving = 'driving';
  static const liveMapGoTo = 'go-to';
  static const liveMapRequesting = 'requesting';

  static const kycYou = 'you';
  static const kycCars = 'your-cars';

  static const configGeneral = 'general';
  static const configPayment = 'payment';
  static const configNotifications = 'notifications';
}
