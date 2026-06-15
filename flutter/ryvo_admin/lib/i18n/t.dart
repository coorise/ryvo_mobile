/// Minimal nav labels — full i18n wiring comes later; keys mirror en.json.
class T {
  T._();

  static const _nav = {
    'nav.overview': 'Overview',
    'nav.dashboard': 'Dashboard',
    'nav.liveMap': 'Live map',
    'nav.rides': 'Rides',
    'nav.users': 'Clients',
    'nav.driverKyc': 'Drivers KYC',
    'nav.staff': 'Staff',
    'nav.notifications': 'Notifications',
    'nav.messages': 'Messages',
    'nav.chatSupport': 'Chat support',
    'nav.feedbacks': 'Feedbacks',
    'nav.profile': 'Profile',
    'nav.configurations': 'Configurations',
    'nav.tasks': 'Tasks',
    'nav.payments': 'Payments',
    'nav.security': 'Security logs',
    'nav.activityLogs': 'Activity logs',
    'nav.observability': 'Observability',
    'nav.referrals': 'Referrals',
    'nav.tariffs': 'Tariffs',
    'nav.checkouts': 'Checkouts',
    'nav.paychecks': 'Paychecks',
    'nav.speculativeEstimator': 'Speculative live estimator',
    'nav.analytics': 'Analytics',
    'nav.groups.main': 'Main',
    'nav.groups.communication': 'Communication',
    'nav.groups.humanResources': 'Human resources',
    'nav.groups.finances': 'Finances',
    'nav.groups.audits': 'Audits',
    'nav.groups.settings': 'Settings',
    'nav.groups.advanced': 'Advanced',
    'nav.menu': 'Navigation menu',
    'nav.openMenu': 'Open menu',
    'common.signOut': 'Sign out',
    'common.search': 'Search…',
    'landing.nav.features': 'Features',
    'landing.nav.cities': 'Cities',
    'landing.nav.drivers': 'Drivers',
    'landing.nav.safety': 'Safety',
  };

  static String nav(String key) => _nav[key] ?? key;
}
