import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
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
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final controls = ref.watch(listControlsProvider('updated_at'));
    final controlsNotifier = ref.read(
      listControlsProvider('updated_at').notifier,
    );
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
            PaginatedSliceOptions(
              pageSize: controls.pageSize,
              loadMode: controls.loadMode,
              page: controls.page,
              setPage: controlsNotifier.setPage,
              infinitePages: controls.infinitePages,
              setInfinitePages: controlsNotifier.setInfinitePages,
              resetDeps: [
                controls.search,
                controls.activeSort?.key,
                controls.activeSort?.dir.name,
                _statusFilter,
              ],
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPageHeader(
                  title: 'Users',
                  subtitle: 'Manage client accounts, status, and engagement.',
                  action: ShadButton(
                    onPressed: () => context.go(Routes.adminUsersNew),
                    child: const Text('Create user'),
                  ),
                ),
                const SizedBox(height: 16),
                AdminStatGrid(
                  children: [
                    AdminStatCard(
                      icon: LucideIcons.users,
                      label: 'Total Users',
                      value: '${stats.total}',
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
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder: 'Search users by email, name, phone, or id',
                  filters: [
                    AdminFilterSelect(
                      value: _statusFilter,
                      onChanged: (v) => setState(() => _statusFilter = v),
                      options: const [
                        AdminFilterOption(value: 'all', label: 'All statuses'),
                        AdminFilterOption(value: 'active', label: 'Active'),
                        AdminFilterOption(
                          value: 'suspended',
                          label: 'Suspended',
                        ),
                      ],
                    ),
                  ],
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
                else
                  _UsersTable(rows: pagination.visibleItems),
                const SizedBox(height: 12),
                _UsersFooter(
                  total: pagination.total,
                  page: pagination.page,
                  totalPages: pagination.totalPages,
                  showingFrom: pagination.showingFrom,
                  showingTo: pagination.showingTo,
                  hasMore: pagination.hasMore,
                  loadMode: pagination.loadMode,
                  onPageChange: controlsNotifier.setPage,
                  onLoadMore: () => _slice.loadMore(
                    pagination,
                    PaginatedSliceOptions(
                      pageSize: controls.pageSize,
                      loadMode: controls.loadMode,
                      page: controls.page,
                      setPage: controlsNotifier.setPage,
                      infinitePages: controls.infinitePages,
                      setInfinitePages: controlsNotifier.setInfinitePages,
                    ),
                  ),
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
  var rows = all
      .where((u) {
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
      })
      .toList(growable: false);

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
  const _UsersTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return AdminTableCard(
      child: AdminTable(
        child: SizedBox(
          width: 1100,
          child: Column(
            children: [
              AdminTableHead(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 290,
                        child: Text('User', style: headerStyle),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text('Role', style: headerStyle),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('Last Seen', style: headerStyle),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('Status', style: headerStyle),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('Actions', style: headerStyle),
                      ),
                    ],
                  ),
                ),
              ),
              ...rows.map((u) {
                final isSuspended = u['banned_at'] != null;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 290,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              child: Text(
                                _initial(
                                  u['full_name']?.toString() ??
                                      u['email']?.toString() ??
                                      '?',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['full_name']?.toString() ??
                                        u['email']?.toString() ??
                                        '—',
                                  ),
                                  Text(
                                    '${u['email'] ?? '—'} · ${_shortId(u['id']?.toString())}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                        child: StatusBadge(
                          label: 'Client',
                          variant: StatusBadgeVariant.info,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text(
                          _formatDateTime(u['updated_at']?.toString()),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: StatusBadge(
                          label: isSuspended ? 'Suspended' : 'Active',
                          variant: isSuspended
                              ? StatusBadgeVariant.danger
                              : StatusBadgeVariant.success,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: InlineRowActions(
                          onView: () {
                            final id = u['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go('${Routes.adminUsersProfile}?id=$id');
                            }
                          },
                          onEdit: () {
                            final id = u['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go('${Routes.adminUsersProfile}?id=$id');
                            }
                          },
                          onToggle: () {
                            final id = u['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go('${Routes.adminUsersProfile}?id=$id');
                            }
                          },
                          profileLabel: 'Profile',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersFooter extends StatelessWidget {
  const _UsersFooter({
    required this.total,
    required this.page,
    required this.totalPages,
    required this.showingFrom,
    required this.showingTo,
    required this.hasMore,
    required this.loadMode,
    required this.onPageChange,
    required this.onLoadMore,
  });

  final int total;
  final int page;
  final int totalPages;
  final int showingFrom;
  final int showingTo;
  final bool hasMore;
  final ListLoadMode loadMode;
  final ValueChanged<int> onPageChange;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Text('Showing $showingFrom-$showingTo of $total'),
        if (loadMode == ListLoadMode.pages) ...[
          OutlinedButton(
            onPressed: page > 1 ? () => onPageChange(page - 1) : null,
            child: const Text('Prev'),
          ),
          Text('Page $page / $totalPages'),
          OutlinedButton(
            onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
            child: const Text('Next'),
          ),
        ] else
          OutlinedButton(
            onPressed: hasMore ? onLoadMore : null,
            child: const Text('Load more'),
          ),
      ],
    );
  }
}

String _formatDateTime(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return DateFormat.yMd().add_Hm().format(dt.toLocal());
}

String _shortId(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value.length <= 8
      ? value.toUpperCase()
      : value.substring(0, 8).toUpperCase();
}

String _initial(String text) =>
    text.trim().isEmpty ? '?' : text.trim()[0].toUpperCase();
