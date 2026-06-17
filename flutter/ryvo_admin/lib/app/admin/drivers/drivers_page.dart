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
import 'package:ryvo_admin/services/drivers_service.dart';
import 'package:ryvo_admin/services/kyc_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

final _driversProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return const [];
  final res = await driversService.listDrivers(token);
  final rows = res['drivers'];
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
});

final _kycQueueProvider = FutureProvider<int>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return 0;
  try {
    final queue = await kycService.getQueue(token);
    final rows = queue['queue'];
    if (rows is List) return rows.length;
    return 0;
  } catch (_) {
    return 0;
  }
});

class AdminDriversPage extends ConsumerStatefulWidget {
  const AdminDriversPage({super.key});

  @override
  ConsumerState<AdminDriversPage> createState() => _AdminDriversPageState();
}

class _AdminDriversPageState extends ConsumerState<AdminDriversPage> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _kycFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'drivers';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final driversAsync = ref.watch(_driversProvider);
    final queueCount = ref.watch(_kycQueueProvider).valueOrNull ?? 0;

    return PermissionGate(
      permissions: const ['drivers:read'],
      fallback: const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('No access')),
      ),
      child: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load drivers: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (allDrivers) {
          final stats = _driverStats(allDrivers);
          final drivers = _filterAndSortDrivers(allDrivers, controls, _kycFilter);
          final pagination = _slice.call(
            drivers,
            adminPaginatedOptions(
              controls: controls,
              notifier: controlsNotifier,
              resetDeps: [
                controls.search,
                controls.activeSort?.key,
                controls.activeSort?.dir.name,
                _kycFilter,
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
                  title: 'Drivers KYC',
                  subtitle: 'Drivers KYC queue and registered drivers · $queueCount pending in queue.',
                  action: ShadButton(
                    onPressed: () => context.go(Routes.adminDriversNew),
                    child: const Text('Create driver'),
                  ),
                ),
                const SizedBox(height: 16),
                AdminCollapsibleOverview(
                  summary:
                      '${stats.total} drivers · ${stats.pending} pending KYC · ${stats.approved} approved',
                  child: AdminStatGrid(
                    children: [
                      AdminStatCard(
                        icon: LucideIcons.car,
                        label: 'Total Drivers',
                        value: '${stats.total}',
                      ),
                      AdminStatCard(
                        icon: LucideIcons.clock3,
                        label: 'Pending KYC',
                        value: '${stats.pending}',
                        tone: AdminStatTone.warning,
                      ),
                      AdminStatCard(
                        icon: LucideIcons.checkCircle2,
                        label: 'Approved',
                        value: '${stats.approved}',
                        tone: AdminStatTone.success,
                      ),
                      AdminStatCard(
                        icon: LucideIcons.xCircle,
                        label: 'Rejected',
                        value: '${stats.rejected}',
                        tone: AdminStatTone.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder: 'Search drivers by name, email, ID…',
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
                    value: _kycFilter,
                    onChanged: (v) => setState(() => _kycFilter = v),
                    options: const [
                      AdminFilterOption(value: 'all', label: 'All statuses'),
                      AdminFilterOption(value: 'pending', label: 'Pending'),
                      AdminFilterOption(value: 'approved', label: 'Approved'),
                      AdminFilterOption(value: 'rejected', label: 'Rejected'),
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
                  _DriversTable(
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
                      for (final d in pagination.visibleItems)
                        _DriverGridCard(
                          driver: d,
                          selected: _selection.isSelected(rowId(d)),
                          onToggleSelected: () {
                            _selection.toggle(rowId(d));
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

class _DriverStats {
  const _DriverStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
}

_DriverStats _driverStats(List<Map<String, dynamic>> all) {
  return _DriverStats(
    total: all.length,
    pending: all.where((d) => (d['kyc_status']?.toString() ?? '') == 'pending').length,
    approved: all.where((d) => (d['kyc_status']?.toString() ?? '') == 'approved').length,
    rejected: all.where((d) => (d['kyc_status']?.toString() ?? '') == 'rejected').length,
  );
}

List<Map<String, dynamic>> _filterAndSortDrivers(
  List<Map<String, dynamic>> all,
  ListControlsState controls,
  String kycFilter,
) {
  final q = controls.search.trim().toLowerCase();
  var rows = all.where((d) {
    final kycStatus = d['kyc_status']?.toString() ?? '';
    if (kycFilter != 'all' && kycStatus != kycFilter) return false;
    if (q.isEmpty) return true;
    final email = (d['email']?.toString() ?? '').toLowerCase();
    final name = (d['full_name']?.toString() ?? '').toLowerCase();
    final id = (d['id']?.toString() ?? '').toLowerCase();
    return email.contains(q) || name.contains(q) || id.contains(q);
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

class _DriversTable extends StatelessWidget {
  const _DriversTable({
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
          width: 1200,
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
                        width: 260,
                        child: SortableTableHeader(
                          label: 'User',
                          sortKey: 'name',
                          activeSort: activeSort,
                          onSort: onSort,
                        ),
                      ),
                      SizedBox(width: 130, child: Text('KYC Status', style: headerStyle)),
                      SizedBox(width: 130, child: Text('Rating', style: headerStyle)),
                      SizedBox(width: 90, child: Text('Trips', style: headerStyle)),
                      SizedBox(
                        width: 170,
                        child: SortableTableHeader(
                          label: 'Last seen',
                          sortKey: 'updated_at',
                          activeSort: activeSort,
                          onSort: onSort,
                        ),
                      ),
                      SizedBox(width: 160, child: Text('Actions', style: headerStyle)),
                    ],
                  ),
                ),
              ),
              for (final d in rows)
                _DriverTableRow(
                  driver: d,
                  selected: selection.isSelected(rowId(d)),
                  onToggleSelected: () => onToggleRow(rowId(d)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverTableRow extends StatelessWidget {
  const _DriverTableRow({
    required this.driver,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> driver;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final id = rowId(driver);
    final status = driver['kyc_status']?.toString() ?? 'unknown';
    final actions = InlineRowActions(
      onView: id.isEmpty ? null : () => context.go('${Routes.adminDriversProfile}?id=$id'),
      onEdit: id.isEmpty
          ? null
          : () => context.go('${Routes.adminDriversProfile}?id=$id&tab=documents'),
      onToggle: id.isEmpty ? null : () => context.go('${Routes.adminDriversProfile}?id=$id'),
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
            AdminListSelectCheckbox(checked: selected, onChanged: onToggleSelected),
            SizedBox(
              width: 260,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(
                      _initial(driver['full_name']?.toString() ?? driver['email']?.toString() ?? '?'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver['full_name']?.toString() ?? driver['email']?.toString() ?? '—'),
                        Text(
                          '${driver['email'] ?? '—'} · ${_shortId(driver['id']?.toString())}',
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
            SizedBox(
              width: 130,
              child: StatusBadge(label: status, variant: _kycVariant(status)),
            ),
            SizedBox(
              width: 130,
              child: _Stars(value: (driver['rating_avg'] as num?)?.toDouble() ?? 0),
            ),
            SizedBox(
              width: 90,
              child: Text('${(driver['trip_count'] as num?)?.toInt() ?? 0}'),
            ),
            SizedBox(
              width: 170,
              child: Text(_formatDateTime(driver['updated_at']?.toString())),
            ),
            SizedBox(width: 160, child: actions),
          ],
        ),
      ),
    );
  }
}

class _DriverGridCard extends StatelessWidget {
  const _DriverGridCard({
    required this.driver,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> driver;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final id = rowId(driver);
    final status = driver['kyc_status']?.toString() ?? 'unknown';
    final actions = InlineRowActions(
      onView: id.isEmpty ? null : () => context.go('${Routes.adminDriversProfile}?id=$id'),
      onEdit: id.isEmpty
          ? null
          : () => context.go('${Routes.adminDriversProfile}?id=$id&tab=documents'),
      onToggle: id.isEmpty ? null : () => context.go('${Routes.adminDriversProfile}?id=$id'),
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
                  _initial(driver['full_name']?.toString() ?? driver['email']?.toString() ?? '?'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['full_name']?.toString() ?? driver['email']?.toString() ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _shortId(driver['id']?.toString()),
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
              StatusBadge(label: status, variant: _kycVariant(status)),
              _Stars(value: (driver['rating_avg'] as num?)?.toDouble() ?? 0),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(driver['trip_count'] as num?)?.toInt() ?? 0} trips · ${_formatDateTime(driver['updated_at']?.toString())}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final full = value.floor().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full ? LucideIcons.star : LucideIcons.starOff,
            size: 14,
            color: i < full ? const Color(0xFFF59E0B) : Theme.of(context).disabledColor,
          ),
        const SizedBox(width: 4),
        Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

StatusBadgeVariant _kycVariant(String status) {
  return switch (status) {
    'approved' => StatusBadgeVariant.success,
    'pending' => StatusBadgeVariant.warning,
    'rejected' => StatusBadgeVariant.danger,
    _ => StatusBadgeVariant.defaultVariant,
  };
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
