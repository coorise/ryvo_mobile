import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
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
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final controls = ref.watch(listControlsProvider('created_at'));
    final controlsNotifier = ref.read(
      listControlsProvider('created_at').notifier,
    );
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
                  title: 'Rides',
                  subtitle:
                      '${stats.inProgress} in progress · ${stats.total} total · ${stats.cancelRate.toStringAsFixed(1)}% cancel rate',
                  action: ShadButton.outline(
                    onPressed: () {},
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
                AdminStatGrid(
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
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder:
                      'Search rides by id, pickup, dropoff, client or driver',
                  filters: [
                    AdminFilterSelect(
                      value: _statusFilter,
                      onChanged: (v) => setState(() => _statusFilter = v),
                      options: const [
                        AdminFilterOption(value: 'all', label: 'All statuses'),
                        AdminFilterOption(value: 'pending', label: 'Pending'),
                        AdminFilterOption(value: 'matched', label: 'Matched'),
                        AdminFilterOption(
                          value: 'cancelled',
                          label: 'Cancelled',
                        ),
                        AdminFilterOption(value: 'expired', label: 'Expired'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ListControlsRow(
                  controls: controls,
                  notifier: controlsNotifier,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (pagination.visibleItems.isEmpty) {
                      return const AdminTableCard(
                        isEmpty: true,
                        empty: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No data')),
                        ),
                        child: SizedBox.shrink(),
                      );
                    }
                    if (constraints.maxWidth < 920) {
                      return Column(
                        children: pagination.visibleItems
                            .map(_RideCard.new)
                            .toList(growable: false),
                      );
                    }
                    return _RidesTable(rows: pagination.visibleItems);
                  },
                ),
                const SizedBox(height: 12),
                _PaginationFooter(
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

class _ListControlsRow extends StatelessWidget {
  const _ListControlsRow({required this.controls, required this.notifier});

  final ListControlsState controls;
  final ListControlsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AdminFilterSelect(
          width: 150,
          value: controls.loadMode.name,
          onChanged: (v) => notifier.setLoadMode(
            v == 'pages' ? ListLoadMode.pages : ListLoadMode.infinite,
          ),
          options: const [
            AdminFilterOption(value: 'infinite', label: 'Infinite'),
            AdminFilterOption(value: 'pages', label: 'Pages'),
          ],
        ),
        AdminFilterSelect(
          width: 120,
          value: '${controls.pageSize}',
          onChanged: (v) =>
              notifier.setPageSize(int.tryParse(v) ?? controls.pageSize),
          options: const [
            AdminFilterOption(value: '10', label: '10'),
            AdminFilterOption(value: '20', label: '20'),
            AdminFilterOption(value: '30', label: '30'),
            AdminFilterOption(value: '50', label: '50'),
          ],
        ),
      ],
    );
  }
}

class _RidesTable extends StatelessWidget {
  const _RidesTable({required this.rows});

  final List<Map<String, dynamic>> rows;

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
              ...rows.map((trip) => _RideRow(trip: trip)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    final status = trip['status']?.toString() ?? 'unknown';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
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
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard(this.trip);

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
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
      crossAxisAlignment: WrapCrossAlignment.center,
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
