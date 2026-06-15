import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/configs/admin_nav.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/admin_access.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/hooks/use_admin_dashboard.dart';
import 'package:ryvo_admin/i18n/t.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class AdminSidebarNav extends ConsumerStatefulWidget {
  const AdminSidebarNav({super.key, this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  ConsumerState<AdminSidebarNav> createState() => _AdminSidebarNavState();
}

class _AdminSidebarNavState extends ConsumerState<AdminSidebarNav> {
  late Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _defaultExpanded();
    _loadExpanded();
  }

  Map<String, bool> _defaultExpanded() {
    return {
      for (final g in AdminNav.groups) g.id: g.defaultExpanded,
    };
  }

  Future<void> _loadExpanded() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(AppConst.storageNavExpanded);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _expanded = {..._defaultExpanded(), ...decoded.map((k, v) => MapEntry(k, v == true))};
      });
    } catch (_) {}
  }

  Future<void> _persistExpanded(Map<String, bool> next) async {
    setState(() => _expanded = next);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConst.storageNavExpanded, jsonEncode(next));
  }

  void _toggleGroup(String id) {
    _persistExpanded({..._expanded, id: !(_expanded[id] ?? false)});
  }

  @override
  Widget build(BuildContext context) {
    final user = useAuth(ref).user;
    final path = GoRouterState.of(context).uri.path;
    final activeGroups = AdminAccess.adminNavGroupsForPath(path);

    for (final id in activeGroups) {
      if (_expanded[id] != true) {
        _expanded = {..._expanded, id: true};
      }
    }

    bool canSee(AdminNavItemConfig item) => AdminAccess.canSeeAdminNavItem(user, item);

    final badges = ref.watch(adminDashboardProvider).valueOrNull?.badges ?? const {};

    String? badgeLabel(AdminNavItemConfig item) {
      if (item.badgeLive) return 'Live';
      final key = item.badge;
      if (key == null) return null;
      final n = (badges[key] as num?)?.toInt();
      if (n == null || n <= 0) return null;
      return n > 99 ? '99+' : '$n';
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (canSee(AdminNav.overview)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              T.nav('nav.overview').toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          _NavTile(
            item: AdminNav.overview,
            active: AdminAccess.isNavActive(path, AdminNav.overview.href),
            badgeLabel: null,
            onTap: () => _go(AdminNav.overview.href),
          ),
        ],
        for (final group in AdminNav.groups) ...[
          if (group.items.any(canSee)) ...[
            _GroupHeader(
              label: T.nav(group.labelKey),
              expanded: _expanded[group.id] ?? group.defaultExpanded,
              onTap: () => _toggleGroup(group.id),
            ),
            if (_expanded[group.id] ?? group.defaultExpanded)
              for (final item in group.items)
                if (canSee(item))
                  _NavTile(
                    item: item,
                    active: AdminAccess.isNavActive(path, item.href),
                    badgeLabel: badgeLabel(item),
                    onTap: () => _go(item.href),
                  ),
          ],
        ],
      ],
    );
  }

  void _go(String href) {
    widget.onNavigate?.call();
    context.go(href);
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      trailing: Icon(expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16),
      onTap: onTap,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.badgeLabel,
  });

  final AdminNavItemConfig item;
  final bool active;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(item.icon, size: 18, color: active ? primary : null),
      title: Text(
        T.nav(item.labelKey),
        style: TextStyle(
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? primary : null,
        ),
      ),
      trailing: badgeLabel != null
          ? ShadBadge(child: Text(badgeLabel!))
          : item.badgeLive
              ? ShadBadge(child: const Text('Live'))
              : null,
      selected: active,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
