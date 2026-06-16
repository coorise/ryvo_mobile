import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/services/rbac_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

final _usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return const [];
  final res = await rbacService.listUsers(token, kind: 'clients');
  final rows = res['users'];
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _statusFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'users';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final usersAsync = ref.watch(_usersProvider);

    return PermissionGate(
      permissions: const ['users:read'],
      fallback: const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('No access')),
      ),
      child: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load users: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (allUsers) {
          final stats = _usersStats(allUsers);
          final users = _filterAndSortUsers(allUsers, controls, _statusFilter);
          final pagination = _slice.call(
            users,
            adminPaginatedOptions(
              controls: controls,
              notifier: controlsNotifier,
              resetDeps: [
                controls.search,
                controls.activeSort?.key,
                controls.activeSort?.dir.name,
                _statusFilter,
                controls.layout.name,
              ],
            ),
          );
          final visibleIds = pagination.visibleItems.map(rowId).toList(growable: false);
          final sliceOptions = adminPaginatedOptions(
            controls: controls,
            notifier: controlsNotifier,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPageHeader(
                  title: 'Clients',
                  subtitle: 'Client accounts — search, suspend, and review activity.',
                  action: ShadButton(
                    onPressed: () => context.go(Routes.adminUsersNew),
                    child: const Text('Create user'),
                  ),
                ),
                const SizedBox(height: 16),
                AdminCollapsibleOverview(
                  summary:
                      '${stats.total} users · ${stats.active} active · ${stats.suspended} suspended',
                  child: AdminStatGrid(
                    children: [
                      AdminStatCard(
                        icon: LucideIcons.users,
                        label: 'Total Users',
                        value: '${stats.total}',
                        hint: 'Registered clients',
                      ),
                      AdminStatCard(
                        icon: LucideIcons.userCheck,
                        label: 'Active Users',
                        value: '${stats.active}',
                        hint: stats.total == 0
                            ? null
                            : '${((stats.active / stats.total) * 100).round()}% of total',
                        tone: AdminStatTone.success,
                      ),
                      AdminStatCard(
                        icon: LucideIcons.userX,
                        label: 'Suspended',
                        value: '${stats.suspended}',
                        hint: 'Manual action',
                        tone: AdminStatTone.warning,
                      ),
                      const AdminStatCard(
                        icon: LucideIcons.alertTriangle,
                        label: 'Flagged',
                        value: '0',
                        hint: '—',
                        tone: AdminStatTone.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder: 'Search by name, email, ID, phone…',
                ),
                const SizedBox(height: 10),
                AdminListLayoutToolbar(
                  layout: controls.layout,
                  onLayoutChange: controlsNotifier.setLayout,
                  loadMode: controls.loadMode,
                  onLoadModeChange: controlsNotifier.setLoadMode,
                  pageSize: controls.pageSize,
                  onPageSizeChange: controlsNotifier.setPageSize,
                  gridSortValue: controls.gridSortValue,
                  onGridSortValueChange: controlsNotifier.setGridSortValue,
                  sortOptions: adminEntityGridSortOptions(),
                  filters: AdminFilterSelect(
                    value: _statusFilter,
                    onChanged: (v) => setState(() => _statusFilter = v),
                    options: const [
                      AdminFilterOption(value: 'all', label: 'All statuses'),
                      AdminFilterOption(value: 'active', label: 'Active'),
                      AdminFilterOption(value: 'suspended', label: 'Suspended'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AdminBulkSelectionBar(
                  count: _selection.count,
                  onClear: () {
                    _selection.clear();
                    _refreshSelection();
                  },
                ),
                const SizedBox(height: 12),
                if (pagination.visibleItems.isEmpty)
                  const AdminTableCard(
                    isEmpty: true,
                    empty: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No data')),
                    ),
                    child: SizedBox.shrink(),
                  )
                else if (controls.layout == ListLayout.table)
                  _UsersTable(
                    rows: pagination.visibleItems,
                    selection: _selection,
                    activeSort: controls.sort == null
                        ? null
                        : SortModel(
                            key: controls.sort!.key,
                            dir: controls.sort!.dir == SortDir.asc
                                ? SortDirection.asc
                                : SortDirection.desc,
                          ),
                    onSort: controlsNotifier.toggleColumnSort,
                    allSelected: _selection.isAllSelected(visibleIds),
                    someSelected: _selection.isSomeSelected(visibleIds),
                    onToggleAll: () {
                      _selection.toggleAll(visibleIds);
                      _refreshSelection();
                    },
                    onToggleRow: (id) {
                      _selection.toggle(id);
                      _refreshSelection();
                    },
                  )
                else
                  AdminEntityGrid(
                    children: [
                      for (final u in pagination.visibleItems)
                        _UserGridCard(
                          user: u,
                          selected: _selection.isSelected(rowId(u)),
                          onToggleSelected: () {
                            _selection.toggle(rowId(u));
                            _refreshSelection();
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                AdminListPaginationFooter(
                  loadMode: pagination.loadMode,
                  total: pagination.total,
                  page: pagination.page,
                  totalPages: pagination.totalPages,
                  showingFrom: pagination.showingFrom,
                  showingTo: pagination.showingTo,
                  hasMore: pagination.hasMore,
                  onPageChange: controlsNotifier.setPage,
                  onLoadMore: () => _slice.loadMore(pagination, sliceOptions),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserStats {
  const _UserStats({
    required this.total,
    required this.active,
    required this.suspended,
  });

  final int total;
  final int active;
  final int suspended;
}

_UserStats _usersStats(List<Map<String, dynamic>> all) {
  final active = all.where((u) => u['banned_at'] == null).length;
  final suspended = all.where((u) => u['banned_at'] != null).length;
  return _UserStats(total: all.length, active: active, suspended: suspended);
}

List<Map<String, dynamic>> _filterAndSortUsers(
  List<Map<String, dynamic>> all,
  ListControlsState controls,
  String statusFilter,
) {
  final q = controls.search.trim().toLowerCase();
  var rows = all.where((u) {
    final isBanned = u['banned_at'] != null;
    if (statusFilter == 'active' && isBanned) return false;
    if (statusFilter == 'suspended' && !isBanned) return false;
    if (q.isEmpty) return true;
    final email = (u['email']?.toString() ?? '').toLowerCase();
    final name = (u['full_name']?.toString() ?? '').toLowerCase();
    final phone = (u['phone']?.toString() ?? '').toLowerCase();
    final id = (u['id']?.toString() ?? '').toLowerCase();
    return email.contains(q) ||
        name.contains(q) ||
        phone.contains(q) ||
        id.contains(q);
  }).toList(growable: false);

  final sort = controls.activeSort;
  if (sort != null) {
    rows = [...rows]
      ..sort((a, b) {
        if (sort.key == 'email') {
          return compareSortable(a['email'], b['email'], sort.dir);
        }
        if (sort.key == 'name') {
          return compareSortable(
            a['full_name'] ?? a['email'],
            b['full_name'] ?? b['email'],
            sort.dir,
          );
        }
        return compareSortable(a['updated_at'], b['updated_at'], sort.dir);
      });
  }

  return rows;
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.rows,
    required this.selection,
    required this.activeSort,
    required this.onSort,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleAll,
    required this.onToggleRow,
  });

  final List<Map<String, dynamic>> rows;
  final BulkSelection selection;
  final SortModel? activeSort;
  final ValueChanged<String> onSort;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onToggleRow;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return AdminTableCard(
      child: AdminTable(
        child: SizedBox(
          width: 1140,
          child: Column(
            children: [
              AdminTableHead(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: AdminListSelectCheckbox(
                          checked: allSelected,
                          indeterminate: someSelected,
                          onChanged: onToggleAll,
                          semanticLabel: 'Select all',
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: SortableTableHeader(
                          label: 'User',
                          sortKey: 'name',
                          activeSort: activeSort,
                          onSort: onSort,
                        ),
                      ),
                      SizedBox(width: 120, child: Text('Role', style: headerStyle)),
                      SizedBox(
                        width: 170,
                        child: SortableTableHeader(
                          label: 'Last seen',
                          sortKey: 'updated_at',
                          activeSort: activeSort,
                          onSort: onSort,
                        ),
                      ),
                      SizedBox(width: 130, child: Text('Status', style: headerStyle)),
                      SizedBox(width: 180, child: Text('Actions', style: headerStyle)),
                    ],
                  ),
                ),
              ),
              for (final u in rows) _UserTableRow(
                user: u,
                selected: selection.isSelected(rowId(u)),
                onToggleSelected: () => onToggleRow(rowId(u)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({
    required this.user,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> user;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final id = rowId(user);
    final isSuspended = user['banned_at'] != null;
    final actions = InlineRowActions(
      onView: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      onEdit: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      onToggle: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      profileLabel: 'Profile',
    );

    return AdminListRowShell(
      selected: selected,
      onToggleSelected: onToggleSelected,
      actions: actions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            AdminListSelectCheckbox(
              checked: selected,
              onChanged: onToggleSelected,
            ),
            SizedBox(
              width: 250,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(
                      _initial(user['full_name']?.toString() ?? user['email']?.toString() ?? '?'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['full_name']?.toString() ?? user['email']?.toString() ?? '—'),
                        Text(
                          '${user['email'] ?? '—'} · ${_shortId(user['id']?.toString())}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 120,
              child: StatusBadge(label: 'Client', variant: StatusBadgeVariant.info),
            ),
            SizedBox(
              width: 170,
              child: Text(_formatDateTime(user['updated_at']?.toString())),
            ),
            SizedBox(
              width: 130,
              child: StatusBadge(
                label: isSuspended ? 'Suspended' : 'Active',
                variant: isSuspended ? StatusBadgeVariant.danger : StatusBadgeVariant.success,
              ),
            ),
            SizedBox(width: 180, child: actions),
          ],
        ),
      ),
    );
  }
}

class _UserGridCard extends StatelessWidget {
  const _UserGridCard({
    required this.user,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> user;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final id = rowId(user);
    final isSuspended = user['banned_at'] != null;
    final actions = InlineRowActions(
      onView: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      onEdit: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      onToggle: id.isEmpty ? null : () => context.go('${Routes.adminUsersProfile}?id=$id'),
      profileLabel: 'Profile',
    );

    return AdminEntityGridCard(
      selected: selected,
      onTap: onToggleSelected,
      actions: InlineRowActionsSpeedDial(actions: actions),
      selection: AdminListSelectCheckbox(compact: true, 
        checked: selected,
        onChanged: onToggleSelected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  _initial(user['full_name']?.toString() ?? user['email']?.toString() ?? '?'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['full_name']?.toString() ?? user['email']?.toString() ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _shortId(user['id']?.toString()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const StatusBadge(label: 'Client', variant: StatusBadgeVariant.info),
              StatusBadge(
                label: isSuspended ? 'Suspended' : 'Active',
                variant: isSuspended ? StatusBadgeVariant.danger : StatusBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(user['updated_at']?.toString()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return DateFormat.yMd().add_jm().format(dt.toLocal());
}

String _shortId(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value.length <= 8 ? value.toUpperCase() : value.substring(0, 8).toUpperCase();
}

String _initial(String text) =>
    text.trim().isEmpty ? '?' : text.trim()[0].toUpperCase();
