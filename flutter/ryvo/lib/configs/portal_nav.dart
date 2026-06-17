import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/configs/const.dart';

enum PortalArea { driver, client }

class PortalNavGroupIds {
  PortalNavGroupIds._();

  static const main = 'main';
  static const communication = 'communication';
  static const hr = 'hr';
  static const finances = 'finances';
  static const audits = 'audits';
  static const settings = 'settings';
}

class PortalNavItem {
  const PortalNavItem({
    required this.href,
    required this.labelKey,
    required this.icon,
    this.roles,
    this.permissions,
    this.permPrefixes,
  });

  final String href;
  final String labelKey;
  final IconData icon;
  final List<String>? roles;
  final List<String>? permissions;
  final List<String>? permPrefixes;
}

class PortalNavGroup {
  const PortalNavGroup({
    required this.id,
    required this.labelKey,
    required this.defaultExpanded,
    required this.items,
  });

  final String id;
  final String labelKey;
  final bool defaultExpanded;
  final List<PortalNavItem> items;
}

class PortalNavConfig {
  const PortalNavConfig({
    required this.homeHref,
    required this.overview,
    required this.groups,
  });

  final String homeHref;
  final PortalNavItem overview;
  final List<PortalNavGroup> groups;
}

class PortalRoutes {
  PortalRoutes._();

  static const driverHome = Routes.driverHome;
  static const driverLiveMap = Routes.driverLiveMap;
  static const driverRides = Routes.driverRides;
  static const driverClients = Routes.driverClients;
  static const driverKyc = Routes.driverKyc;
  static const driverNotifications = Routes.driverNotifications;
  static const driverChat = Routes.driverChat;
  static const driverMessages = Routes.driverMessages;
  static const driverChatSupport = Routes.driverChatSupport;
  static const driverFeedbacks = Routes.driverFeedbacks;
  static const driverPayments = Routes.driverPayments;
  static const driverSecurityLogs = Routes.driverSecurityLogs;
  static const driverActivityLogs = Routes.driverActivityLogs;
  static const driverAnalytics = Routes.driverAnalytics;
  static const driverProfile = Routes.driverProfile;
  static const driverConfigurations = Routes.driverConfigurations;

  static const clientHome = Routes.clientHome;
  static const clientLiveMap = Routes.clientLiveMap;
  static const clientRides = Routes.clientRides;
  static const clientDrivers = Routes.clientDrivers;
  static const clientNotifications = Routes.clientNotifications;
  static const clientChat = Routes.clientChat;
  static const clientChatSupport = Routes.clientChatSupport;
  static const clientFeedbacks = Routes.clientFeedbacks;
  static const clientPayments = Routes.clientPayments;
  static const clientSecurityLogs = Routes.clientSecurityLogs;
  static const clientActivityLogs = Routes.clientActivityLogs;
  static const clientAnalytics = Routes.clientAnalytics;
  static const clientProfile = Routes.clientProfile;
  static const clientConfigurations = Routes.clientConfigurations;
}

final driverNav = PortalNavConfig(
  homeHref: PortalRoutes.driverHome,
  overview: const PortalNavItem(
    href: PortalRoutes.driverHome,
    labelKey: 'portal.nav.overview',
    icon: LucideIcons.layoutDashboard,
  ),
  groups: [
    PortalNavGroup(
      id: PortalNavGroupIds.main,
      labelKey: 'portal.nav.groups.main',
      defaultExpanded: true,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverLiveMap,
          labelKey: 'portal.nav.liveMap',
          icon: LucideIcons.map,
        ),
        PortalNavItem(
          href: PortalRoutes.driverRides,
          labelKey: 'portal.nav.rides',
          icon: LucideIcons.car,
        ),
        PortalNavItem(
          href: PortalRoutes.driverClients,
          labelKey: 'portal.nav.clients',
          icon: LucideIcons.users,
        ),
        PortalNavItem(
          href: PortalRoutes.driverKyc,
          labelKey: 'portal.nav.driverKyc',
          icon: LucideIcons.fileText,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.communication,
      labelKey: 'portal.nav.groups.communication',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverNotifications,
          labelKey: 'portal.nav.notifications',
          icon: LucideIcons.bell,
        ),
        PortalNavItem(
          href: PortalRoutes.driverChat,
          labelKey: 'portal.nav.chat',
          icon: LucideIcons.messageSquare,
        ),
        PortalNavItem(
          href: PortalRoutes.driverMessages,
          labelKey: 'portal.nav.messages',
          icon: LucideIcons.mail,
        ),
        PortalNavItem(
          href: PortalRoutes.driverChatSupport,
          labelKey: 'portal.nav.chatSupport',
          icon: LucideIcons.messagesSquare,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.hr,
      labelKey: 'portal.nav.groups.hr',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverFeedbacks,
          labelKey: 'portal.nav.feedbacks',
          icon: LucideIcons.star,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.finances,
      labelKey: 'portal.nav.groups.finances',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverPayments,
          labelKey: 'portal.nav.payments',
          icon: LucideIcons.wallet,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.audits,
      labelKey: 'portal.nav.groups.audits',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverSecurityLogs,
          labelKey: 'portal.nav.securityLogs',
          icon: LucideIcons.shield,
        ),
        PortalNavItem(
          href: PortalRoutes.driverActivityLogs,
          labelKey: 'portal.nav.activityLogs',
          icon: LucideIcons.fileText,
        ),
        PortalNavItem(
          href: PortalRoutes.driverAnalytics,
          labelKey: 'portal.nav.analytics',
          icon: LucideIcons.barChart3,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.settings,
      labelKey: 'portal.nav.groups.settings',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.driverProfile,
          labelKey: 'portal.nav.profile',
          icon: LucideIcons.user,
        ),
        PortalNavItem(
          href: PortalRoutes.driverConfigurations,
          labelKey: 'portal.nav.configurations',
          icon: LucideIcons.slidersHorizontal,
        ),
      ],
    ),
  ],
);

final clientNav = PortalNavConfig(
  homeHref: PortalRoutes.clientHome,
  overview: const PortalNavItem(
    href: PortalRoutes.clientHome,
    labelKey: 'portal.nav.overview',
    icon: LucideIcons.layoutDashboard,
  ),
  groups: [
    PortalNavGroup(
      id: PortalNavGroupIds.main,
      labelKey: 'portal.nav.groups.main',
      defaultExpanded: true,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientLiveMap,
          labelKey: 'portal.nav.liveMap',
          icon: LucideIcons.map,
        ),
        PortalNavItem(
          href: PortalRoutes.clientRides,
          labelKey: 'portal.nav.rides',
          icon: LucideIcons.car,
        ),
        PortalNavItem(
          href: PortalRoutes.clientDrivers,
          labelKey: 'portal.nav.drivers',
          icon: LucideIcons.user,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.communication,
      labelKey: 'portal.nav.groups.communication',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientNotifications,
          labelKey: 'portal.nav.notifications',
          icon: LucideIcons.bell,
        ),
        PortalNavItem(
          href: PortalRoutes.clientChat,
          labelKey: 'portal.nav.chat',
          icon: LucideIcons.messageSquare,
        ),
        PortalNavItem(
          href: PortalRoutes.clientChatSupport,
          labelKey: 'portal.nav.chatSupport',
          icon: LucideIcons.messagesSquare,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.hr,
      labelKey: 'portal.nav.groups.hr',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientFeedbacks,
          labelKey: 'portal.nav.feedbacks',
          icon: LucideIcons.star,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.finances,
      labelKey: 'portal.nav.groups.finances',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientPayments,
          labelKey: 'portal.nav.payments',
          icon: LucideIcons.creditCard,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.audits,
      labelKey: 'portal.nav.groups.audits',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientSecurityLogs,
          labelKey: 'portal.nav.securityLogs',
          icon: LucideIcons.shield,
        ),
        PortalNavItem(
          href: PortalRoutes.clientActivityLogs,
          labelKey: 'portal.nav.activityLogs',
          icon: LucideIcons.fileText,
        ),
        PortalNavItem(
          href: PortalRoutes.clientAnalytics,
          labelKey: 'portal.nav.analytics',
          icon: LucideIcons.barChart3,
        ),
      ],
    ),
    PortalNavGroup(
      id: PortalNavGroupIds.settings,
      labelKey: 'portal.nav.groups.settings',
      defaultExpanded: false,
      items: const [
        PortalNavItem(
          href: PortalRoutes.clientProfile,
          labelKey: 'portal.nav.profile',
          icon: LucideIcons.user,
        ),
        PortalNavItem(
          href: PortalRoutes.clientConfigurations,
          labelKey: 'portal.nav.configurations',
          icon: LucideIcons.slidersHorizontal,
        ),
      ],
    ),
  ],
);

PortalNavConfig portalNavForArea(PortalArea area) {
  return area == PortalArea.driver ? driverNav : clientNav;
}

Set<String> portalNavGroupsForPath(String pathname, PortalNavConfig config) {
  final active = <String>{};
  for (final group in config.groups) {
    if (group.items.any((item) => pathname == item.href || pathname.startsWith('${item.href}/'))) {
      active.add(group.id);
    }
  }
  return active;
}

final portalPathPrefixes = <PortalArea, List<({String prefix, PortalNavItem item})>>{
  PortalArea.driver: [
    for (final item in [driverNav.overview, ...driverNav.groups.expand((g) => g.items)])
      (prefix: item.href, item: item),
  ],
  PortalArea.client: [
    for (final item in [clientNav.overview, ...clientNav.groups.expand((g) => g.items)])
      (prefix: item.href, item: item),
  ],
};
