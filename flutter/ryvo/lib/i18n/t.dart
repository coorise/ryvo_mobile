import 'package:ryvo/i18n/app_i18n.dart';

/// Translation helper — keys mirror web i18next.
class T {
  T._();

  static const _nav = {
    'landing.nav.features': 'Features',
    'landing.nav.cities': 'Cities',
    'landing.nav.drivers': 'Drivers',
    'landing.nav.safety': 'Safety',
    'landing.goToDashboard': 'Go to dashboard',
    'landing.goHome': 'Go home',
    'common.signIn': 'Sign in',
    'common.register': 'Register',
    'common.about': 'About',
    'common.cancel': 'Cancel',
    'nav.menu': 'Navigation menu',
    'auth.back': 'Back',
    'auth.login.title': 'Sign in',
    'auth.login.description': 'Driver and client accounts only.',
    'auth.login.email': 'Email',
    'auth.login.emailPlaceholder': 'you@email.com',
    'auth.login.password': 'Password',
    'auth.login.passwordPlaceholder': 'Your password',
    'auth.login.signingIn': 'Signing in…',
    'auth.login.forgotPassword': 'Forgot password?',
    'auth.login.noAccount': 'No account? Create one',
    'auth.login.staffBlocked': 'Staff accounts must use the admin app.',
    'auth.login.noPortalAccess': 'This account does not have portal access.',
    'auth.register.title': 'Create account',
    'auth.register.description': 'Join Ryvo-Line as a rider or driver.',
    'auth.register.fullName': 'Full name',
    'auth.register.email': 'Email',
    'auth.register.password': 'Password',
    'auth.register.confirmPassword': 'Confirm password',
    'auth.register.rider': 'Rider',
    'auth.register.driver': 'Driver',
    'auth.register.submit': 'Create account',
    'auth.register.creating': 'Creating…',
    'auth.register.haveAccount': 'Already have an account? Sign in',
    'auth.verifyEmail.title': 'Verify your email',
    'auth.verifyEmail.description':
        'We sent a confirmation link. Open it to unlock booking and driving.',
    'auth.verifyEmail.sentTo': 'Sent to',
    'auth.verifyEmail.backToSignIn': 'Back to sign in',
  };

  static const _portal = {
    'portal.nav.overview': 'Overview',
    'portal.nav.liveMap': 'Live map',
    'portal.nav.rides': 'Rides',
    'portal.nav.clients': 'Clients',
    'portal.nav.drivers': 'Drivers',
    'portal.nav.driverKyc': 'Driver KYC',
    'portal.nav.notifications': 'Notifications',
    'portal.nav.chat': 'Chat',
    'portal.nav.messages': 'Messages',
    'portal.nav.chatSupport': 'Chat support',
    'portal.nav.feedbacks': 'Feedbacks',
    'portal.nav.payments': 'Payments',
    'portal.nav.securityLogs': 'Security logs',
    'portal.nav.activityLogs': 'Activity logs',
    'portal.nav.analytics': 'Analytics',
    'portal.nav.profile': 'Profile',
    'portal.nav.configurations': 'Configurations',
    'portal.nav.groups.main': 'Main',
    'portal.nav.groups.communication': 'Communication',
    'portal.nav.groups.hr': 'Human resources',
    'portal.nav.groups.finances': 'Finances',
    'portal.nav.groups.audits': 'Audits',
    'portal.nav.groups.settings': 'Settings',
    'portal.shell.driver': 'Driver',
    'portal.shell.client': 'Client',
    'portal.settings.tabs.general': 'General',
    'portal.settings.tabs.payment': 'Payment',
    'portal.settings.tabs.notifications': 'Notifications',
    'portal.home.open': 'Open',
    'portal.home.driver.subtitle':
        'Your driver workspace — go online, manage trips, and track earnings.',
    'portal.home.driver.liveMapTitle': 'Live map',
    'portal.home.driver.liveMapDesc': 'Set your presence, zone pricing, and incoming requests.',
    'portal.home.client.subtitle': 'Book rides, track trips, and manage your account.',
    'portal.home.client.liveMapTitle': 'Find a ride',
    'portal.home.client.liveMapDesc': 'Search destinations and request a driver near you.',
    'portal.rides.subtitle': 'Trip history and your active ride.',
    'portal.clients.subtitle': 'Clients you have driven.',
    'portal.drivers.subtitle': 'Drivers you have ridden with.',
    'common.signOut': 'Sign out',
  };

  static String nav(String key) {
    final translated = AppI18n.instance.tr(key);
    if (translated != key) return translated;
    return _nav[key] ?? key;
  }

  static String portal(String key) {
    final translated = AppI18n.instance.tr(key);
    if (translated != key) return translated;
    return _portal[key] ?? key;
  }
}
