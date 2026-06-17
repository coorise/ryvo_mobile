import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/guards/abac.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

bool canSeePortalNavItem(SessionUser? user, PortalNavItem item) {
  if (user == null) return false;
  if (item.roles != null && item.roles!.isNotEmpty && !Abac.hasRole(user, item.roles!)) {
    return false;
  }
  if (item.permissions != null &&
      item.permissions!.isNotEmpty &&
      !Abac.hasAnyPermission(user, item.permissions!)) {
    return false;
  }
  if (item.permPrefixes != null && item.permPrefixes!.isNotEmpty) {
    final ok = item.permPrefixes!.any((p) => Abac.hasPermPrefix(user, p));
    if (!ok) return false;
  }
  return true;
}

PortalNavItem? _resolveRuleForPath(PortalArea area, String pathname) {
  final path = pathname.replaceAll(RegExp(r'/$'), '');
  final base = area == PortalArea.driver ? '/driver' : '/client';
  if (!path.startsWith(base)) return null;

  for (final entry in portalPathPrefixes[area]!) {
    final normalized = entry.prefix.replaceAll(RegExp(r'/$'), '');
    if (path == normalized || path.startsWith('$normalized/')) {
      return entry.item;
    }
  }
  return null;
}

bool canAccessPortalPath(SessionUser? user, PortalArea area, String pathname) {
  if (user == null) return false;
  final config = portalNavForArea(area);
  final home = config.homeHref;
  final rule = _resolveRuleForPath(area, pathname);
  if (rule == null) {
    return pathname == home || pathname == '$home/';
  }
  return canSeePortalNavItem(user, rule);
}

String firstAllowedPortalPath(SessionUser? user, PortalArea area) {
  final config = portalNavForArea(area);
  if (canSeePortalNavItem(user, config.overview)) return config.homeHref;
  for (final group in config.groups) {
    for (final item in group.items) {
      if (canSeePortalNavItem(user, item)) return item.href;
    }
  }
  return config.homeHref;
}

bool isNavActive(String path, String href) {
  if (path == href) return true;
  if (href == '/driver' || href == '/client') return path == href;
  return path.startsWith('$href/');
}
