import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

class Abac {
  Abac._();

  static bool hasRole(SessionUser? user, List<String> roles) {
    if (user == null) return false;
    if (user.roles.contains('super_admin')) return true;
    return roles.any(user.roles.contains);
  }

  static bool hasPermission(SessionUser? user, String permission) {
    if (user == null) return false;
    if (user.roles.contains('super_admin')) return true;
    return user.permissions.contains(permission);
  }

  static bool hasPermPrefix(SessionUser? user, String prefix) {
    if (user == null) return false;
    if (user.roles.contains('super_admin')) return true;
    final p = prefix.endsWith(':') ? prefix : '$prefix:';
    return user.permissions.any((name) => name == prefix || name.startsWith(p));
  }

  static bool canAccessDashboard(SessionUser? user, {String area = 'admin'}) {
    if (user == null) return false;
    if (area != 'admin') return false;
    return canAccessAdmin(user) ||
        hasPermPrefix(user, 'roles:') ||
        hasPermPrefix(user, 'staff:') ||
        hasPermPrefix(user, 'users:') ||
        hasPermPrefix(user, 'drivers:') ||
        hasPermPrefix(user, 'rides:') ||
        hasPermPrefix(user, 'support:') ||
        hasPermPrefix(user, 'audit:') ||
        hasPermPrefix(user, 'settings:') ||
        hasPermPrefix(user, 'payments:') ||
        hasPermPrefix(user, 'observability:') ||
        hasPermPrefix(user, 'finances:') ||
        hasPermPrefix(user, 'analytics:') ||
        hasPermPrefix(user, 'feedbacks:') ||
        hasPermPrefix(user, 'communication:') ||
        hasPermPrefix(user, 'map:') ||
        hasPermPrefix(user, 'tasks:');
  }

  static bool canAccessAdmin(SessionUser? user) {
    if (user == null) return false;
    return hasRole(user, const [
      'super_admin',
      'admin',
      'staff',
      'moderator',
      'agent',
      'support',
    ]);
  }

  static bool canViewStaffSection(SessionUser? user) {
    return hasPermission(user, 'staff:read') || hasPermission(user, 'roles:read');
  }

  static String dashboardPathForUser(SessionUser? user) {
    if (user == null) return Routes.authLogin;
    if (canAccessAdmin(user) || canAccessDashboard(user)) return Routes.adminHome;
    return Routes.authLogin;
  }
}
