import 'package:ryvo_admin/configs/admin_nav.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

/// Mirrors web `guards/admin-access.ts`.
class AdminAccess {
  AdminAccess._();

  static bool canSeeAdminNavItem(SessionUser? user, AdminNavItemConfig item) {
    if (user == null || !Abac.canAccessDashboard(user)) return false;
    if (item.alwaysForAdmin) return true;
    if (item.staffSection && !Abac.canViewStaffSection(user)) return false;
    if (user.roles.contains('super_admin')) return true;
    if (item.permissions.any((p) => Abac.hasPermission(user, p))) return true;
    if (item.permPrefixes.any((p) => Abac.hasPermPrefix(user, p))) return true;
    if (item.href == Routes.adminHome) {
      return AdminNav.overview.permPrefixes.any((p) => Abac.hasPermPrefix(user, p));
    }
    return false;
  }

  static AdminNavItemConfig? resolveRuleForPath(String pathname) {
    var path = pathname.replaceAll(RegExp(r'/+$'), '');
    if (path.isEmpty) path = Routes.adminHome;
    if (!path.startsWith('/admin')) return null;

    for (final entry in AdminNav.pathPrefixes) {
      final normalized = entry.prefix.replaceAll(RegExp(r'/+$'), '');
      if (path == normalized || path.startsWith('$normalized/')) {
        return entry.item;
      }
    }
    return null;
  }

  static bool canAccessAdminPath(SessionUser? user, String pathname) {
    if (user == null || !Abac.canAccessDashboard(user)) return false;
    final rule = resolveRuleForPath(pathname);
    if (rule == null) {
      return pathname == Routes.adminHome || pathname == '$Routes.adminHome/';
    }
    return canSeeAdminNavItem(user, rule);
  }

  static String firstAllowedAdminPath(SessionUser? user) {
    if (canSeeAdminNavItem(user, AdminNav.overview)) return Routes.adminHome;
    for (final group in AdminNav.groups) {
      for (final item in group.items) {
        if (canSeeAdminNavItem(user, item)) return item.href;
      }
    }
    return Routes.landing;
  }

  static Set<String> adminNavGroupsForPath(String pathname) {
    final ids = <String>{};
    for (final group in AdminNav.groups) {
      for (final item in group.items) {
        if (_isNavActive(pathname, item.href)) {
          ids.add(group.id);
        }
      }
    }
    return ids;
  }

  static bool _isNavActive(String pathname, String href) {
    if (href == Routes.adminHome) {
      return pathname == Routes.adminHome || pathname == '$Routes.adminHome/';
    }
    return pathname == href || pathname.startsWith('$href/');
  }

  static bool isNavActive(String pathname, String href) => _isNavActive(pathname, href);
}
