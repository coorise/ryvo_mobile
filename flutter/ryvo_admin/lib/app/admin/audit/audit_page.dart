import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/lib/audit_utils.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminAuditPage extends ConsumerStatefulWidget {
  const AdminAuditPage({super.key});

  @override
  ConsumerState<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends ConsumerState<AdminAuditPage> {
  Future<Map<String, dynamic>>? _future;
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _categoryFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return auditService.listActivityLogs(
      ref.read(authProvider).accessToken,
      limit: 300,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> rows,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var filtered = rows.where((log) {
      final action = log['action']?.toString() ?? '';
      if (_categoryFilter != 'all' &&
          auditActionCategory(action) != _categoryFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return action.toLowerCase().contains(q) ||
          (log['target_type']?.toString().toLowerCase().contains(q) ?? false) ||
          (log['target_id']?.toString().toLowerCase().contains(q) ?? false) ||
          (log['actor_id']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      filtered = [...filtered]
        ..sort((a, b) {
          if (sort.key == 'action') {
            return compareSortable(a['action'], b['action'], sort.dir);
          }
          return compareSortable(a['created_at'], b['created_at'], sort.dir);
        });
    }
    return filtered;
  }

  Map<String, int> _stats(List<Map<String, dynamic>> rows) {
    final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
    final today = rows.where((l) {
      final created = DateTime.tryParse(l['created_at']?.toString() ?? '');
      return created != null && !created.isBefore(dayAgo);
    }).length;
    final actors = rows
        .map((l) => l['actor_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .length;
    final finance = rows
        .where((l) => auditActionCategory(l['action']?.toString() ?? '') == 'finance')
        .length;
    return {
      'total': rows.length,
      'today': today,
      'actors': actors,
      'finance': finance,
    };
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'audit';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const ['audit:read'],
      fallback: const Center(child: Text('No access to audit logs.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Activity Logs',
              subtitle: 'Recent admin activity and changes.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AdminTableCard(
                    isEmpty: true,
                    empty: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Failed to load logs: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }
                final raw = snapshot.data?['logs'];
                final rows = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];
                final stats = _stats(rows);
                final filtered = _filterAndSort(rows, controls);
                final pagination = _slice.call(
                  filtered,
                  adminPaginatedOptions(
                    controls: controls,
                    notifier: controlsNotifier,
                    resetDeps: [
                      controls.search,
                      controls.activeSort?.key,
                      controls.activeSort?.dir.name,
                      _categoryFilter,
                      controls.layout.name,
                    ],
                  ),
                );
                final sliceOptions = adminPaginatedOptions(
                  controls: controls,
                  notifier: controlsNotifier,
                );

                return AdminListStack(
                  children: [
                    AdminCollapsibleOverview(
                      summary:
                          '${stats['total']} total · ${stats['today']} last 24h · ${stats['actors']} actors',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            label: 'Total',
                            value: '${stats['total']}',
                            icon: Icons.list_alt,
                          ),
                          AdminStatCard(
                            label: 'Last 24h',
                            value: '${stats['today']}',
                            icon: Icons.today,
                            tone: AdminStatTone.info,
                          ),
                          AdminStatCard(
                            label: 'Actors',
                            value: '${stats['actors']}',
                            icon: Icons.person_outline,
                          ),
                          AdminStatCard(
                            label: 'Finance',
                            value: '${stats['finance']}',
                            icon: Icons.payments_outlined,
                            tone: AdminStatTone.warning,
                          ),
                        ],
                      ),
                    ),
                    AdminSearchToolbar(
                      value: controls.search,
                      onChanged: controlsNotifier.setSearch,
                      placeholder: 'Search logs',
                    ),
                    const SizedBox(height: 10),
                    AdminManagedListToolbarSection(
                      controls: controls,
                      notifier: controlsNotifier,
                      selection: _selection,
                      onSelectionChanged: _refreshSelection,
                      sortOptions: const [
                        AdminFilterOption(value: 'created_at:desc', label: 'Newest first'),
                        AdminFilterOption(value: 'created_at:asc', label: 'Oldest first'),
                        AdminFilterOption(value: 'action:asc', label: 'Action A–Z'),
                        AdminFilterOption(value: 'action:desc', label: 'Action Z–A'),
                      ],
                      filters: AdminFilterSelect(
                        value: _categoryFilter,
                        onChanged: (v) => setState(() => _categoryFilter = v),
                        options: const [
                          AdminFilterOption(value: 'all', label: 'All'),
                          AdminFilterOption(value: 'user', label: 'Users'),
                          AdminFilterOption(value: 'driver', label: 'Drivers'),
                          AdminFilterOption(value: 'finance', label: 'Finance'),
                          AdminFilterOption(value: 'admin', label: 'Admin'),
                          AdminFilterOption(value: 'other', label: 'Other'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No activity logs found.'),
                      ),
                      table: AdminTableCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagination.visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = pagination.visibleItems[index];
                            final id = rowId(log);
                            final action = log['action']?.toString() ?? 'action';
                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              leading: StatusBadge(
                                label: auditActionCategory(action),
                                variant: StatusBadgeVariant.defaultVariant,
                              ),
                              title: Text(action),
                              subtitle: Text(
                                'Actor: ${log['actor_id'] ?? '—'} · Target: ${log['target_type'] ?? '—'}:${log['target_id'] ?? '—'}\n${log['created_at'] ?? ''}',
                              ),
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final log in pagination.visibleItems)
                            _AuditLogGridCard(
                              log: log,
                              selected: _selection.isSelected(rowId(log)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(log));
                                _refreshSelection();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminManagedListFooterSection(
                      pagination: pagination,
                      notifier: controlsNotifier,
                      slice: _slice,
                      sliceOptions: sliceOptions,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogGridCard extends StatelessWidget {
  const _AuditLogGridCard({
    required this.log,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> log;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? 'action';
    return AdminEntityGridCard(
      selected: selected,
      onTap: onToggleSelected,
      selection: AdminListSelectCheckbox(compact: true, 
        checked: selected,
        onChanged: onToggleSelected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(action, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          StatusBadge(
            label: auditActionCategory(action),
            variant: StatusBadgeVariant.defaultVariant,
          ),
          const SizedBox(height: 6),
          Text(
            '${log['created_at'] ?? ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
