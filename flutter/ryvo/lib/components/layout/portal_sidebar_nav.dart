import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/guards/portal_access.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/stores/auth_store.dart';

class PortalSidebarNav extends ConsumerStatefulWidget {
  const PortalSidebarNav({super.key, required this.area, this.onNavigate});

  final PortalArea area;
  final VoidCallback? onNavigate;

  @override
  ConsumerState<PortalSidebarNav> createState() => _PortalSidebarNavState();
}

class _PortalSidebarNavState extends ConsumerState<PortalSidebarNav> {
  late Map<String, bool> _expanded;

  PortalNavConfig get _config => portalNavForArea(widget.area);

  String get _storageKey => '${AppConst.storageNavExpanded}.${widget.area.name}';

  @override
  void initState() {
    super.initState();
    _expanded = _defaultExpanded();
    _loadExpanded();
  }

  Map<String, bool> _defaultExpanded() {
    return {
      for (final g in _config.groups) g.id: g.defaultExpanded,
    };
  }

  Future<void> _loadExpanded() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _expanded = {..._defaultExpanded(), ...decoded.map((k, v) => MapEntry(k, v == true))};
      });
    } catch (_) {}
  }

  Future<void> _persistExpanded(Map<String, bool> next) async {
    setState(() => _expanded = next);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storageKey, jsonEncode(next));
  }

  void _toggleGroup(String id) {
    _persistExpanded({..._expanded, id: !(_expanded[id] ?? false)});
  }

  @override
  Widget build(BuildContext context) {
    final user = useAuth(ref).user;
    final path = GoRouterState.of(context).uri.path;
    final activeGroups = portalNavGroupsForPath(path, _config);

    for (final id in activeGroups) {
      if (_expanded[id] != true) {
        _expanded = {..._expanded, id: true};
      }
    }

    bool canSee(PortalNavItem item) => canSeePortalNavItem(user, item);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (canSee(_config.overview)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              T.portal('portal.nav.overview').toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          _NavTile(
            item: _config.overview,
            active: isNavActive(path, _config.overview.href),
            onTap: () => _go(_config.overview.href),
          ),
        ],
        for (final group in _config.groups) ...[
          if (group.items.any(canSee)) ...[
            _GroupHeader(
              label: T.portal(group.labelKey),
              expanded: _expanded[group.id] ?? group.defaultExpanded,
              onTap: () => _toggleGroup(group.id),
            ),
            if (_expanded[group.id] ?? group.defaultExpanded)
              for (final item in group.items)
                if (canSee(item))
                  _NavTile(
                    item: item,
                    active: isNavActive(path, item.href),
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
  });

  final PortalNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(item.icon, size: 18, color: active ? primary : null),
      title: Text(
        T.portal(item.labelKey),
        style: TextStyle(
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? primary : null,
        ),
      ),
      selected: active,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
