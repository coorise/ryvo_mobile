import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/services/drivers_service.dart';
import 'package:ryvo_admin/services/kyc_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

final _driversProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
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
  String _kycFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final controls = ref.watch(listControlsProvider('updated_at'));
    final controlsNotifier = ref.read(
      listControlsProvider('updated_at').notifier,
    );
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
          final drivers = _filterAndSortDrivers(
            allDrivers,
            controls,
            _kycFilter,
          );
          final pagination = _slice.call(
            drivers,
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
                _kycFilter,
              ],
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPageHeader(
                  title: 'Driver KYC',
                  subtitle:
                      '$queueCount items currently waiting in the KYC queue.',
                  action: ShadButton(
                    onPressed: () => context.go(Routes.adminDriversNew),
                    child: const Text('Create driver'),
                  ),
                ),
                const SizedBox(height: 16),
                AdminStatGrid(
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
                      label: 'Approved KYC',
                      value: '${stats.approved}',
                      tone: AdminStatTone.success,
                    ),
                    AdminStatCard(
                      icon: LucideIcons.xCircle,
                      label: 'Rejected KYC',
                      value: '${stats.rejected}',
                      tone: AdminStatTone.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AdminSearchToolbar(
                  value: controls.search,
                  onChanged: controlsNotifier.setSearch,
                  placeholder: 'Search drivers by email, name, or id',
                  filters: [
                    AdminFilterSelect(
                      value: _kycFilter,
                      onChanged: (v) => setState(() => _kycFilter = v),
                      options: const [
                        AdminFilterOption(value: 'all', label: 'All statuses'),
                        AdminFilterOption(value: 'pending', label: 'Pending'),
                        AdminFilterOption(value: 'approved', label: 'Approved'),
                        AdminFilterOption(value: 'rejected', label: 'Rejected'),
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
                  _DriversTable(rows: pagination.visibleItems),
                const SizedBox(height: 12),
                _DriversFooter(
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
    pending: all
        .where((d) => (d['kyc_status']?.toString() ?? '') == 'pending')
        .length,
    approved: all
        .where((d) => (d['kyc_status']?.toString() ?? '') == 'approved')
        .length,
    rejected: all
        .where((d) => (d['kyc_status']?.toString() ?? '') == 'rejected')
        .length,
  );
}

List<Map<String, dynamic>> _filterAndSortDrivers(
  List<Map<String, dynamic>> all,
  ListControlsState controls,
  String kycFilter,
) {
  final q = controls.search.trim().toLowerCase();
  var rows = all
      .where((d) {
        final kycStatus = d['kyc_status']?.toString() ?? '';
        if (kycFilter != 'all' && kycStatus != kycFilter) return false;
        if (q.isEmpty) return true;
        final email = (d['email']?.toString() ?? '').toLowerCase();
        final name = (d['full_name']?.toString() ?? '').toLowerCase();
        final id = (d['id']?.toString() ?? '').toLowerCase();
        return email.contains(q) || name.contains(q) || id.contains(q);
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

class _DriversTable extends StatelessWidget {
  const _DriversTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return AdminTableCard(
      child: AdminTable(
        child: SizedBox(
          width: 1160,
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
                        width: 300,
                        child: Text('Driver', style: headerStyle),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('KYC Status', style: headerStyle),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('Rating', style: headerStyle),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text('Trips', style: headerStyle),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('Last Seen', style: headerStyle),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('Actions', style: headerStyle),
                      ),
                    ],
                  ),
                ),
              ),
              ...rows.map((d) {
                final status = d['kyc_status']?.toString() ?? 'unknown';
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
                        width: 300,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              child: Text(
                                _initial(
                                  d['full_name']?.toString() ??
                                      d['email']?.toString() ??
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
                                    d['full_name']?.toString() ??
                                        d['email']?.toString() ??
                                        '—',
                                  ),
                                  Text(
                                    '${d['email'] ?? '—'} · ${_shortId(d['id']?.toString())}',
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
                      SizedBox(
                        width: 140,
                        child: StatusBadge(
                          label: status,
                          variant: _kycVariant(status),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: _Stars(
                          value: (d['rating_avg'] as num?)?.toDouble() ?? 0,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${(d['trip_count'] as num?)?.toInt() ?? 0}',
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text(
                          _formatDateTime(d['updated_at']?.toString()),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: InlineRowActions(
                          onView: () {
                            final id = d['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go('${Routes.adminDriversProfile}?id=$id');
                            }
                          },
                          onEdit: () {
                            final id = d['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go(
                                '${Routes.adminDriversProfile}?id=$id&tab=documents',
                              );
                            }
                          },
                          onToggle: () {
                            final id = d['id']?.toString();
                            if (id != null && id.isNotEmpty) {
                              context.go('${Routes.adminDriversProfile}?id=$id');
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

class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final full = value.floor().clamp(0, 5);
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full ? LucideIcons.star : LucideIcons.starOff,
            size: 14,
            color: i < full
                ? const Color(0xFFF59E0B)
                : Theme.of(context).disabledColor,
          ),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DriversFooter extends StatelessWidget {
  const _DriversFooter({
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
