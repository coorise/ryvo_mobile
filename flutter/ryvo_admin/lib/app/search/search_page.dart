import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/configs/admin_nav.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/admin_access.dart';
import 'package:ryvo_admin/i18n/t.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class AdminSearchPage extends ConsumerStatefulWidget {
  const AdminSearchPage({super.key});

  @override
  ConsumerState<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends ConsumerState<AdminSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<({String href, String label, String group, IconData icon})> _allResults() {
    final user = ref.read(authProvider).user;
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

  List<({String href, String label, String group, IconData icon})> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allResults().take(20).toList(growable: false);
    return _allResults()
        .where((r) => r.label.toLowerCase().contains(q) || r.group.toLowerCase().contains(q))
        .take(30)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search admin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.adminHome),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search pages and sections…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) {
                final first = _results;
                if (first.isNotEmpty) context.go(first.first.href);
              },
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'Type to search admin navigation.' : 'No results for "$_query".',
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = _results[index];
                      return ListTile(
                        leading: Icon(row.icon),
                        title: Text(row.label),
                        subtitle: Text(row.group),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(row.href),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
