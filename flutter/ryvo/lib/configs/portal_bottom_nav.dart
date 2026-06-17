import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';

class PortalBottomNavItem {
  const PortalBottomNavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.matchPrefixes,
  });

  final String route;
  final String labelKey;
  final IconData icon;
  final List<String> matchPrefixes;
}

List<PortalBottomNavItem> portalBottomNavItems(PortalArea area) {
  if (area == PortalArea.driver) {
    return const [
      PortalBottomNavItem(
        route: Routes.driverLiveMap,
        labelKey: 'portal.bottomNav.home',
        icon: LucideIcons.map,
        matchPrefixes: [Routes.driverLiveMap],
      ),
      PortalBottomNavItem(
        route: Routes.driverRides,
        labelKey: 'portal.bottomNav.orders',
        icon: LucideIcons.car,
        matchPrefixes: [Routes.driverRides, '/driver/drive'],
      ),
      PortalBottomNavItem(
        route: Routes.driverAnalytics,
        labelKey: 'portal.bottomNav.analytics',
        icon: LucideIcons.barChart3,
        matchPrefixes: [Routes.driverAnalytics],
      ),
      PortalBottomNavItem(
        route: Routes.driverChatSupport,
        labelKey: 'portal.bottomNav.support',
        icon: LucideIcons.messagesSquare,
        matchPrefixes: [Routes.driverChatSupport],
      ),
      PortalBottomNavItem(
        route: Routes.driverProfile,
        labelKey: 'portal.bottomNav.profile',
        icon: LucideIcons.user,
        matchPrefixes: [Routes.driverProfile],
      ),
    ];
  }

  return const [
    PortalBottomNavItem(
      route: Routes.clientLiveMap,
      labelKey: 'portal.bottomNav.home',
      icon: LucideIcons.map,
      matchPrefixes: [Routes.clientLiveMap],
    ),
    PortalBottomNavItem(
      route: Routes.clientRides,
      labelKey: 'portal.bottomNav.orders',
      icon: LucideIcons.car,
      matchPrefixes: [Routes.clientRides, '/client/drive'],
    ),
    PortalBottomNavItem(
      route: Routes.clientAnalytics,
      labelKey: 'portal.bottomNav.analytics',
      icon: LucideIcons.barChart3,
      matchPrefixes: [Routes.clientAnalytics],
    ),
    PortalBottomNavItem(
      route: Routes.clientChatSupport,
      labelKey: 'portal.bottomNav.support',
      icon: LucideIcons.messagesSquare,
      matchPrefixes: [Routes.clientChatSupport],
    ),
    PortalBottomNavItem(
      route: Routes.clientProfile,
      labelKey: 'portal.bottomNav.profile',
      icon: LucideIcons.user,
      matchPrefixes: [Routes.clientProfile],
    ),
  ];
}

int portalBottomNavIndexForPath(PortalArea area, String path) {
  final items = portalBottomNavItems(area);
  for (var i = 0; i < items.length; i++) {
    for (final prefix in items[i].matchPrefixes) {
      if (path == prefix || path.startsWith('$prefix/')) return i;
    }
  }
  return 0;
}

String portalDefaultEntryPath(PortalArea area) {
  return area == PortalArea.driver ? Routes.driverLiveMap : Routes.clientLiveMap;
}
