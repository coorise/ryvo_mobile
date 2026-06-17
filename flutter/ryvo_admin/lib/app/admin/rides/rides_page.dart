import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/lib/csv_export.dart';
import 'package:ryvo_admin/services/admin_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

final _ridesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return const [];
  final res = await adminService.listTrips(token, limit: 200);
  final rows = res['trips'];
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
});

class AdminRidesPage extends ConsumerStatefulWidget {
  const AdminRidesPage({super.key});

  @override
  ConsumerState<AdminRidesPage> createState() => _AdminRidesPageState();
}

class _AdminRidesPageState extends ConsumerState<AdminRidesPage> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _statusFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'rides';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final ridesAsync = ref.watch(_ridesProvider);

    return PermissionGate(
      permissions: const ['rides:read'],
      fallback: const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('No access')),
      ),
      child: ridesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load rides: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (all) {
          final stats = _ridesStats(all);
          final rows = _filterAndSortRows(all, controls, _statusFilter);
          final pagination = _slice.call(
            rows,
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
                  title: 'Rides',
                  subtitle:
                      '${stats.inProgress} in progress · ${stats.total} total · ${stats.cancelRate.toStringAsFixed(1)}% cancel rate',
                  action: ShadButton.outline(
                    onPressed: () {
                      final csv = rowsToCsv(
                        rows,
                        const ['id', 'pickup_address', 'dropoff_address', 'fare_estimate', 'status', 'created_at'],
                      );
                      showCsvExportDialog(context, title: 'Export rides', csv: csv);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.download, size: 16),
                        SizedBox(width: 6),
                        Text('Export'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AdminCollapsibleOverview(
                  summary:
                      '${stats.total} total · ${stats.inProgress} in progress · ${stats.cancelRate.toStringAsFixed(1)}% cancel',
                  child: AdminStatGrid(
                    children: [
                      AdminStatCard(
                        icon: LucideIcons.car,
                        label: 'Total',
                        value: '${stats.total}',
                      ),
                      AdminStatCard(
                        icon: LucideIcons.clock3,
                        label: 'In Progress',
                        value: '${stats.inProgress}',
                        tone: AdminStatTone.success,
                      ),
                      AdminStatCard(
                        icon: LucideIcons.dollarSign,
                        label: 'Revenue',
                        value: NumberFormat.currency(
                          symbol: r'$',
                        ).format(stats.revenue),
                        tone: AdminStatTone.info,
                      ),
                      AdminStatCard(
                        icon: LucideIcons.xCircle,
                        label: 'Cancel Rate',
                        value: '${stats.cancelRate.toStringAsFixed(1)}%',
                        tone: stats.cancelRate > 5
                            ? AdminStatTone.danger
                            : AdminStatTone.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder:
                      'Search rides by id, pickup, dropoff, client or driver',
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
                    AdminFilterOption(value: 'status:asc', label: 'Status A–Z'),
                    AdminFilterOption(value: 'status:desc', label: 'Status Z–A'),
                  ],
                  filters: AdminFilterSelect(
                    value: _statusFilter,
                    onChanged: (v) => setState(() => _statusFilter = v),
                    options: const [
                      AdminFilterOption(value: 'all', label: 'All statuses'),
                      AdminFilterOption(value: 'pending', label: 'Pending'),
                      AdminFilterOption(value: 'matched', label: 'Matched'),
                      AdminFilterOption(value: 'cancelled', label: 'Cancelled'),
                      AdminFilterOption(value: 'expired', label: 'Expired'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AdminLayoutSwitch(
                  layout: controls.layout,
                  isEmpty: pagination.visibleItems.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No data')),
                  ),
                  table: _RidesTable(
                    rows: pagination.visibleItems,
                    selection: _selection,
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
                  ),
                  grid: AdminEntityGrid(
                    children: [
                      for (final trip in pagination.visibleItems)
                        _RideGridCard(
                          trip: trip,
                          selected: _selection.isSelected(rowId(trip)),
                          onToggleSelected: () {
                            _selection.toggle(rowId(trip));
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
            ),
          );
        },
      ),
    );
  }
}

class _RidesStats {
  const _RidesStats({
    required this.total,
    required this.inProgress,
    required this.cancelled,
    required this.revenue,
    required this.cancelRate,
  });

  final int total;
  final int inProgress;
  final int cancelled;
  final double revenue;
  final double cancelRate;
}

_RidesStats _ridesStats(List<Map<String, dynamic>> all) {
  final total = all.length;
  final inProgress = all
      .where((r) => !_isTripCancelled(r['status']?.toString()))
      .length;
  final cancelled = all
      .where((r) => _isTripCancelled(r['status']?.toString()))
      .length;
  final revenue = all.fold<double>(
    0,
    (sum, r) => sum + ((r['fare_estimate'] as num?)?.toDouble() ?? 0),
  );
  final cancelRate = total == 0 ? 0.0 : (cancelled / total) * 100;
  return _RidesStats(
    total: total,
    inProgress: inProgress,
    cancelled: cancelled,
    revenue: revenue,
    cancelRate: cancelRate,
  );
}

List<Map<String, dynamic>> _filterAndSortRows(
  List<Map<String, dynamic>> all,
  ListControlsState controls,
  String statusFilter,
) {
  final search = controls.search.trim().toLowerCase();
  var items = all
      .where((r) {
        if (statusFilter != 'all' &&
            (r['status']?.toString() ?? '') != statusFilter) {
          return false;
        }
        if (search.isEmpty) return true;
        final id = (r['id']?.toString() ?? '').toLowerCase();
        final pickup = (r['pickup_address']?.toString() ?? '').toLowerCase();
        final dropoff = (r['dropoff_address']?.toString() ?? '').toLowerCase();
        final client = (r['client_id']?.toString() ?? '').toLowerCase();
        final driver = (r['driver_id']?.toString() ?? '').toLowerCase();
        return id.contains(search) ||
            pickup.contains(search) ||
            dropoff.contains(search) ||
            client.contains(search) ||
            driver.contains(search);
      })
      .toList(growable: false);

  final sort = controls.activeSort;
  if (sort != null) {
    items = [...items]
      ..sort((a, b) {
        if (sort.key == 'created_at') {
          return compareSortable(a['created_at'], b['created_at'], sort.dir);
        }
        if (sort.key == 'status') {
          return compareSortable(a['status'], b['status'], sort.dir);
        }
        return compareSortable(a['id'], b['id'], sort.dir);
      });
  }
  return items;
}

class _RidesTable extends StatelessWidget {
  const _RidesTable({
    required this.rows,
    required this.selection,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleAll,
    required this.onToggleRow,
  });

  final List<Map<String, dynamic>> rows;
  final BulkSelection selection;
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
          width: 1180,
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
                        width: 52,
                        child: AdminListSelectCheckbox(
                          checked: allSelected,
                          indeterminate: someSelected,
                          onChanged: onToggleAll,
                          semanticLabel: 'Select all',
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text('ID', style: headerStyle),
                      ),
                      SizedBox(
                        width: 220,
                        child: Text('Pickup', style: headerStyle),
                      ),
                      SizedBox(
                        width: 220,
                        child: Text('Dropoff', style: headerStyle),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text('Fare', style: headerStyle),
                      ),
                      SizedBox(
                        width: 130,
                        child: Text('Status', style: headerStyle),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text('Created', style: headerStyle),
                      ),
                    ],
                  ),
                ),
              ),
              for (final trip in rows)
                _RideRow(
                  trip: trip,
                  selected: selection.isSelected(rowId(trip)),
                  onToggleSelected: () => onToggleRow(rowId(trip)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({
    required this.trip,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> trip;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final status = trip['status']?.toString() ?? 'unknown';
    const actions = InlineRowActions();
    return AdminListRowShell(
      selected: selected,
      onToggleSelected: onToggleSelected,
      actions: actions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            AdminListSelectCheckbox(
              checked: selected,
              onChanged: onToggleSelected,
            ),
            SizedBox(
              width: 120,
              child: Text(
                _shortId(trip['id']?.toString()),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          SizedBox(
            width: 220,
            child: Text(
              _text(trip['pickup_address']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 220,
            child: Text(
              _text(trip['dropoff_address']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              trip['fare_estimate'] == null
                  ? '—'
                  : NumberFormat.currency(
                      symbol: r'$',
                    ).format((trip['fare_estimate'] as num).toDouble()),
            ),
          ),
          SizedBox(
            width: 130,
            child: StatusBadge(
              label: status,
              variant: StatusBadgeVariant.defaultVariant,
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(_formatDateTime(trip['created_at']?.toString())),
          ),
        ],
      ),
    ),
    );
  }
}

class _RideGridCard extends StatelessWidget {
  const _RideGridCard({
    required this.trip,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> trip;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Text(
                _shortId(trip['id']?.toString()),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              StatusBadge(
                label: _text(trip['status']),
                variant: StatusBadgeVariant.defaultVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pickup: ${_text(trip['pickup_address'])}'),
          Text('Dropoff: ${_text(trip['dropoff_address'])}'),
          const SizedBox(height: 6),
          Text(
            'Fare: ${trip['fare_estimate'] == null ? '—' : NumberFormat.currency(symbol: r'$').format((trip['fare_estimate'] as num).toDouble())}',
          ),
          Text('Created: ${_formatDateTime(trip['created_at']?.toString())}'),
        ],
      ),
    );
  }
}

bool _isTripCancelled(String? status) =>
    status == 'cancelled' || status == 'expired';
String _text(Object? value) =>
    value?.toString().trim().isNotEmpty == true ? value.toString() : '—';
String _shortId(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value.length <= 8
      ? value.toUpperCase()
      : value.substring(0, 8).toUpperCase();
}

String _formatDateTime(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return DateFormat.yMd().add_Hm().format(dt.toLocal());
}
