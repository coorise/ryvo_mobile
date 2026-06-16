import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/configs/admin_nav.dart';
import 'package:ryvo_admin/guards/admin_access.dart';
import 'package:ryvo_admin/i18n/t.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

class AdminGlobalSearch extends ConsumerStatefulWidget {
  const AdminGlobalSearch({super.key});

  @override
  ConsumerState<AdminGlobalSearch> createState() => _AdminGlobalSearchState();
}

class _AdminGlobalSearchState extends ConsumerState<AdminGlobalSearch> {
  final _controller = TextEditingController();
  var _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<({String href, String label, String group, IconData icon})> _allResults(
    SessionUser? user,
  ) {
    if (user == null) return [];

    final items = <({String href, String label, String group, IconData icon})>[
      (
        href: AdminNav.overview.href,
        label: T.nav(AdminNav.overview.labelKey),
        group: T.nav('nav.overview'),
        icon: AdminNav.overview.icon,
      ),
    ];

    for (final group in AdminNav.groups) {
      for (final item in group.items) {
        if (!AdminAccess.canSeeAdminNavItem(user, item)) continue;
        items.add((
          href: item.href,
          label: T.nav(item.labelKey),
          group: T.nav(group.labelKey),
          icon: item.icon,
        ));
      }
    }
    return items;
  }

  List<({String href, String label, String group, IconData icon})> _filtered(
    SessionUser? user,
  ) {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _allResults(user)
        .where((r) => r.label.toLowerCase().contains(q) || r.group.toLowerCase().contains(q))
        .take(12)
        .toList();
  }

  void _pick(String href) {
    setState(() {
      _open = false;
      _controller.clear();
    });
    context.go(href);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final results = _open ? _filtered(user) : const [];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadInput(
            controller: _controller,
            placeholder: Text(T.nav('common.search')),
            onChanged: (_) => setState(() => _open = true),
          ),
          if (results.isNotEmpty)
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final r = results[i];
                    return ListTile(
                      leading: Icon(r.icon, size: 18),
                      title: Text(r.label),
                      subtitle: Text(r.group, style: Theme.of(context).textTheme.labelSmall),
                      onTap: () => _pick(r.href),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
