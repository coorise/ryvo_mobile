import 'package:ryvo/configs/const.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

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

  static bool hasAnyPermission(SessionUser? user, List<String> permissions) {
    return permissions.any((p) => hasPermission(user, p));
  }

  static bool hasPermPrefix(SessionUser? user, String prefix) {
    if (user == null) return false;
    if (user.roles.contains('super_admin')) return true;
    final p = prefix.endsWith(':') ? prefix : '$prefix:';
    return user.permissions.any((name) => name == prefix || name.startsWith(p));
  }

  static bool hasStrictRole(SessionUser? user, List<String> roles) {
    if (user == null) return false;
    return roles.any(user.roles.contains);
  }

  static bool canAccessDashboard(SessionUser? user, {String area = 'client'}) {
    if (user == null) return false;
    switch (area) {
      case 'driver':
        return hasRole(user, const ['driver']);
      case 'client':
        return hasRole(user, const ['client']);
      case 'admin':
        return hasRole(user, const [
              'super_admin',
              'admin',
              'staff',
              'moderator',
              'agent',
              'support',
            ]) ||
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
      default:
        return false;
    }
  }

  static bool isPortalUser(SessionUser? user) {
    if (user == null) return false;
    return hasStrictRole(user, const ['driver']) || hasStrictRole(user, const ['client']);
  }

  static String portalDashboardPathForUser(SessionUser? user) {
    if (user == null) return Routes.authLogin;
    if (hasStrictRole(user, const ['driver'])) return Routes.driverHome;
    if (hasStrictRole(user, const ['client'])) return Routes.clientHome;
    return Routes.authLogin;
  }

  static String dashboardPathForUser(SessionUser? user) => portalDashboardPathForUser(user);
}
