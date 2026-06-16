import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/components/admin/finance/payment_preview_dialog.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminPaymentsPage extends ConsumerStatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  ConsumerState<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends ConsumerState<AdminPaymentsPage> {
  Future<Map<String, dynamic>>? _future;
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _status = 'all';

  void _refreshSelection() => setState(() {});

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    final status = _status == 'all' ? null : _status;
    return adminService.listPayments(
      ref.read(authProvider).accessToken,
      status: status,
      limit: 500,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<Map<String, dynamic>> _parseRows(Map<String, dynamic>? data) {
    final raw = data?['payments'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> rows,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var filtered = q.isEmpty
        ? rows
        : rows.where((row) {
            return (row['rider_email']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['provider']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['id']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['provider_intent_id']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['trip_id']?.toString().toLowerCase().contains(q) ?? false);
          }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      filtered = [...filtered]
        ..sort((a, b) {
          if (sort.key == 'status') {
            return compareSortable(a['status'], b['status'], sort.dir);
          }
          return compareSortable(
            a['updated_at'] ?? a['created_at'],
            b['updated_at'] ?? b['created_at'],
            sort.dir,
          );
        });
    }
    return filtered;
  }

  _PaymentStats _stats(List<Map<String, dynamic>> all) {
    final succeeded = all.where((p) => p['status'] == 'succeeded').toList();
    final volume = succeeded.fold<double>(
      0,
      (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
    );
    final pending = all.where((p) => p['status'] != 'succeeded').length;
    return _PaymentStats(
      total: all.length,
      succeeded: succeeded.length,
      volume: volume,
      pending: pending,
    );
  }

  StatusBadgeVariant _statusVariant(String status) {
    if (status == 'succeeded') return StatusBadgeVariant.success;
    if (status == 'pending' ||
        status == 'processing' ||
        status == 'requires_payment_method') {
      return StatusBadgeVariant.warning;
    }
    if (status == 'failed' || status == 'cancelled' || status == 'canceled') {
      return StatusBadgeVariant.danger;
    }
    return StatusBadgeVariant.defaultVariant;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'payments';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const ['payments:read'],
      fallback: const Center(child: Text('No access to payments.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Payments',
              subtitle: 'Payments list from admin API.',
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
                      child: Text('Failed to load payments: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final all = _parseRows(snapshot.data);
                final stats = _stats(all);
                final rows = _filterAndSort(all, controls);
                final pagination = _slice.call(
                  rows,
                  adminPaginatedOptions(
                    controls: controls,
                    notifier: controlsNotifier,
                    resetDeps: [
                      controls.search,
                      controls.activeSort?.key,
                      controls.activeSort?.dir.name,
                      _status,
                      controls.layout.name,
                    ],
                  ),
                );
                final sliceOptions = adminPaginatedOptions(
                  controls: controls,
                  notifier: controlsNotifier,
                );
                final succeededPct = stats.total == 0
                    ? 0
                    : ((stats.succeeded / stats.total) * 100).round();

                return AdminListStack(
                  children: [
                    AdminCollapsibleOverview(
                      summary:
                          '${stats.total} total · ${stats.succeeded} succeeded · ${NumberFormat.currency(symbol: r'$').format(stats.volume)} volume',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            label: 'Total',
                            value: '${stats.total}',
                            icon: Icons.credit_card,
                          ),
                          AdminStatCard(
                            label: 'Succeeded',
                            value: '${stats.succeeded}',
                            icon: Icons.check_circle_outline,
                            tone: AdminStatTone.success,
                          ),
                          AdminStatCard(
                            label: 'Volume',
                            value: NumberFormat.currency(symbol: r'$').format(stats.volume),
                            icon: Icons.payments_outlined,
                            tone: AdminStatTone.info,
                          ),
                          AdminStatCard(
                            label: 'Other statuses',
                            value: '${stats.pending}',
                            icon: Icons.schedule,
                            tone: AdminStatTone.warning,
                          ),
                        ],
                      ),
                    ),
                    if (stats.total > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$succeededPct% of payments succeeded',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    AdminSearchToolbar(
                      value: controls.search,
                      onChanged: controlsNotifier.setSearch,
                      placeholder: 'Search payments',
                    ),
                    const SizedBox(height: 10),
                    AdminManagedListToolbarSection(
                      controls: controls,
                      notifier: controlsNotifier,
                      selection: _selection,
                      onSelectionChanged: _refreshSelection,
                      sortOptions: adminEntityGridSortOptions(),
                      filters: AdminFilterSelect(
                        value: _status,
                        onChanged: (v) => setState(() {
                          _status = v;
                          _future = _load();
                        }),
                        options: const [
                          AdminFilterOption(value: 'all', label: 'All'),
                          AdminFilterOption(value: 'succeeded', label: 'Succeeded'),
                          AdminFilterOption(value: 'pending', label: 'Pending'),
                          AdminFilterOption(value: 'failed', label: 'Failed'),
                          AdminFilterOption(value: 'refunded', label: 'Refunded'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No payments found.'),
                      ),
                      table: AdminTableCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagination.visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = pagination.visibleItems[index];
                            final id = rowId(p);
                            final status = p['status']?.toString() ?? 'unknown';
                            final amount = p['amount'];
                            final currency = p['currency']?.toString() ?? '';
                            final actions = InlineRowActions(
                              onView: () => showPaymentPreviewDialog(context, p),
                            );

                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              onTap: () => showPaymentPreviewDialog(context, p),
                              title: Text('$amount $currency'),
                              subtitle: Text(
                                'Provider: ${p['provider'] ?? '—'} · Rider: ${p['rider_email'] ?? '—'}',
                              ),
                              trailing: StatusBadge(
                                label: status,
                                variant: _statusVariant(status),
                              ),
                              actions: actions,
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final p in pagination.visibleItems)
                            _PaymentGridCard(
                              payment: p,
                              selected: _selection.isSelected(rowId(p)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(p));
                                _refreshSelection();
                              },
                              statusVariant: _statusVariant,
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

class _PaymentGridCard extends StatelessWidget {
  const _PaymentGridCard({
    required this.payment,
    required this.selected,
    required this.onToggleSelected,
    required this.statusVariant,
  });

  final Map<String, dynamic> payment;
  final bool selected;
  final VoidCallback onToggleSelected;
  final StatusBadgeVariant Function(String) statusVariant;

  @override
  Widget build(BuildContext context) {
    final status = payment['status']?.toString() ?? 'unknown';
    final amount = payment['amount'];
    final currency = payment['currency']?.toString() ?? '';
    final actions = InlineRowActions(
      onView: () => showPaymentPreviewDialog(context, payment),
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
          Text('$amount $currency', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          StatusBadge(label: status, variant: statusVariant(status)),
          const SizedBox(height: 6),
          Text(
            '${payment['provider'] ?? '—'} · ${payment['rider_email'] ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
                  ],
      ),
    );
  }
}

class _PaymentStats {
  const _PaymentStats({
    required this.total,
    required this.succeeded,
    required this.volume,
    required this.pending,
  });

  final int total;
  final int succeeded;
  final double volume;
  final int pending;
}
