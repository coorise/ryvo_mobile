import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/configs/const.dart';

/// Mirrors web `configs/admin-nav.ts`.
class AdminNavGroupIds {
  AdminNavGroupIds._();

  static const main = 'main';
  static const communication = 'communication';
  static const hr = 'hr';
  static const finances = 'finances';
  static const audits = 'audits';
  static const settings = 'settings';
  static const advanced = 'advanced';
}

class AdminNavItemConfig {
  const AdminNavItemConfig({
    required this.href,
    required this.labelKey,
    required this.icon,
    this.badge,
    this.badgeLive = false,
    this.permPrefixes = const [],
    this.permissions = const [],
    this.alwaysForAdmin = false,
    this.staffSection = false,
  });

  final String href;
  final String labelKey;
  final IconData icon;
  final String? badge;
  final bool badgeLive;
  final List<String> permPrefixes;
  final List<String> permissions;
  final bool alwaysForAdmin;
  final bool staffSection;
}

class AdminNavGroupConfig {
  const AdminNavGroupConfig({
    required this.id,
    required this.labelKey,
    required this.defaultExpanded,
    required this.items,
  });

  final String id;
  final String labelKey;
  final bool defaultExpanded;
  final List<AdminNavItemConfig> items;
}

class AdminNav {
  AdminNav._();

  static const overview = AdminNavItemConfig(
    href: Routes.adminHome,
    labelKey: 'nav.overview',
    icon: LucideIcons.layoutDashboard,
    permPrefixes: [
      'rides:',
      'users:',
      'drivers:',
      'staff:',
      'roles:',
      'support:',
      'payments:',
      'audit:',
      'settings:',
      'observability:',
      'finances:',
      'analytics:',
    ],
  );

  static const groups = [
    AdminNavGroupConfig(
      id: AdminNavGroupIds.main,
      labelKey: 'nav.groups.main',
      defaultExpanded: true,
      items: [
        AdminNavItemConfig(
          href: Routes.adminMap,
          labelKey: 'nav.liveMap',
          icon: LucideIcons.map,
          badgeLive: true,
          permPrefixes: ['map:', 'rides:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminRides,
          labelKey: 'nav.rides',
          icon: LucideIcons.car,
          badge: 'rides',
          permPrefixes: ['rides:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminUsersList,
          labelKey: 'nav.users',
          icon: LucideIcons.users,
          permPrefixes: ['users:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminDriversList,
          labelKey: 'nav.driverKyc',
          icon: LucideIcons.userCheck,
          badge: 'drivers',
          permPrefixes: ['drivers:'],
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.communication,
      labelKey: 'nav.groups.communication',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminCommNotifications,
          labelKey: 'nav.notifications',
          icon: LucideIcons.bell,
          permPrefixes: ['communication:notifications:', 'settings:notifications:', 'support:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminCommMessages,
          labelKey: 'nav.messages',
          icon: LucideIcons.mail,
          permPrefixes: ['communication:messages:', 'support:reply'],
        ),
        AdminNavItemConfig(
          href: Routes.adminChatSupport,
          labelKey: 'nav.chatSupport',
          icon: LucideIcons.messagesSquare,
          badge: 'tickets',
          permPrefixes: ['communication:chat:', 'support:'],
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.hr,
      labelKey: 'nav.groups.humanResources',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminStaffList,
          labelKey: 'nav.staff',
          icon: LucideIcons.userCog,
          permPrefixes: ['staff:', 'roles:'],
          staffSection: true,
        ),
        AdminNavItemConfig(
          href: Routes.adminHrFeedbacks,
          labelKey: 'nav.feedbacks',
          icon: LucideIcons.star,
          permPrefixes: ['feedbacks:', 'support:'],
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.finances,
      labelKey: 'nav.groups.finances',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminFinanceReferrals,
          labelKey: 'nav.referrals',
          icon: LucideIcons.gift,
          permPrefixes: ['finances:referrals:', 'payments:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminFinanceTariffs,
          labelKey: 'nav.tariffs',
          icon: LucideIcons.tags,
          permPrefixes: ['finances:tariffs:', 'payments:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminFinanceCheckouts,
          labelKey: 'nav.checkouts',
          icon: LucideIcons.shoppingCart,
          permPrefixes: ['finances:checkouts:', 'finances:checkouts:update', 'payments:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminPayments,
          labelKey: 'nav.payments',
          icon: LucideIcons.creditCard,
          permPrefixes: ['payments:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminFinancePaychecks,
          labelKey: 'nav.paychecks',
          icon: LucideIcons.wallet,
          permPrefixes: ['finances:paychecks:', 'payments:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminFinanceSpeculative,
          labelKey: 'nav.speculativeEstimator',
          icon: LucideIcons.trendingUp,
          permPrefixes: ['finances:speculative:', 'payments:'],
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.audits,
      labelKey: 'nav.groups.audits',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminSecurity,
          labelKey: 'nav.security',
          icon: LucideIcons.shield,
          permPrefixes: ['audit:', 'audit:update'],
        ),
        AdminNavItemConfig(
          href: Routes.adminAudit,
          labelKey: 'nav.activityLogs',
          icon: LucideIcons.fileText,
          permPrefixes: ['audit:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminAnalytics,
          labelKey: 'nav.analytics',
          icon: LucideIcons.barChart3,
          permPrefixes: ['analytics:', 'audit:'],
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.settings,
      labelKey: 'nav.groups.settings',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminSettingsProfile,
          labelKey: 'nav.profile',
          icon: LucideIcons.user,
          alwaysForAdmin: true,
        ),
        AdminNavItemConfig(
          href: Routes.adminSettingsConfigurations,
          labelKey: 'nav.configurations',
          icon: LucideIcons.settings,
          alwaysForAdmin: true,
        ),
      ],
    ),
    AdminNavGroupConfig(
      id: AdminNavGroupIds.advanced,
      labelKey: 'nav.groups.advanced',
      defaultExpanded: false,
      items: [
        AdminNavItemConfig(
          href: Routes.adminSettingsTasks,
          labelKey: 'nav.tasks',
          icon: LucideIcons.listTodo,
          permPrefixes: ['settings:'],
        ),
        AdminNavItemConfig(
          href: Routes.adminObservability,
          labelKey: 'nav.observability',
          icon: LucideIcons.gauge,
          permPrefixes: ['observability:', 'settings:'],
        ),
      ],
    ),
  ];

  static List<AdminNavItemConfig> get allItems => [
        overview,
        ...groups.expand((g) => g.items),
      ];

  static List<({String prefix, AdminNavItemConfig item})> get pathPrefixes {
    final entries = allItems.map((item) => (prefix: item.href, item: item)).toList()
      ..sort((a, b) => b.prefix.length.compareTo(a.prefix.length));
    return entries;
  }
}
