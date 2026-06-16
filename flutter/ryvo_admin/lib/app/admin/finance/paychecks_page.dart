import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/components/admin/finance/finance_form_sheets.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/lib/finance_list_helpers.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinancePaychecksPage extends ConsumerStatefulWidget {
  const FinancePaychecksPage({super.key});

  @override
  ConsumerState<FinancePaychecksPage> createState() =>
      _FinancePaychecksPageState();
}

class _FinancePaychecksPageState extends ConsumerState<FinancePaychecksPage> {
  Future<_PaychecksPayload>? _future;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PaychecksPayload> _load() async {
    final token = ref.read(authProvider).accessToken;
    final status = _statusFilter == 'all' ? null : _statusFilter;
    final paychecks = await financeService.getPaychecks(token, status: status);
    final earnings = await financeService.getDriverEarnings(token);
    return _PaychecksPayload(paychecks: paychecks, earnings: earnings);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _setStatus(Map<String, dynamic> row, String status) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await financeService.updatePaycheckStatus(
      ref.read(authProvider).accessToken,
      id,
      status,
    );
    await _refresh();
  }

  Future<void> _deletePaycheck(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await confirmDelete(context, title: 'Delete paycheck?');
    if (!ok) return;
    await financeService.deletePaycheck(ref.read(authProvider).accessToken, id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'paychecks';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const ['finances:paychecks:read', 'payments:read'],
      fallback: const Center(child: Text('You do not have access to paychecks.')),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_PaychecksPayload>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text('Failed to load paychecks: ${snapshot.error}');
              }
              final data = snapshot.data!;
              final paychecks = financeRows(data.paychecks, keys: const ['paychecks']);
              final earnings = financeRows(data.earnings, keys: const ['earnings']);

              return AdminListStack(
                children: [
                  AdminPageHeader(
                    title: 'Paychecks',
                    subtitle: 'Paycheck queue and driver earnings snapshot.',
                    action: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showPaycheckCreateSheet(context, ref);
                            if (ok == true) await _refresh();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New paycheck'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                  AdminSearchToolbar(
                    value: controls.search,
                    onChanged: controlsNotifier.setSearch,
                    placeholder: 'Search paychecks',
                  ),
                  AdminFilterSelect(
                    value: _statusFilter,
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _refresh();
                    },
                    options: const [
                      AdminFilterOption(value: 'all', label: 'All'),
                      AdminFilterOption(value: 'pending', label: 'Pending'),
                      AdminFilterOption(value: 'paid', label: 'Paid'),
                      AdminFilterOption(value: 'held', label: 'Held'),
                      AdminFilterOption(value: 'cancelled', label: 'Cancelled'),
                    ],
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Paying'),
                      Tab(text: 'Drivers Amount'),
                    ],
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _PaychecksListTab(
                          paychecks: paychecks,
                          onSetStatus: _setStatus,
                          onDelete: _deletePaycheck,
                        ),
                        _DriverEarningsTab(
                          earnings: earnings,
                          onRefresh: _refresh,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaychecksListTab extends ConsumerStatefulWidget {
  const _PaychecksListTab({
    required this.paychecks,
    required this.onSetStatus,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> paychecks;
  final Future<void> Function(Map<String, dynamic>, String) onSetStatus;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  ConsumerState<_PaychecksListTab> createState() => _PaychecksListTabState();
}

class _PaychecksListTabState extends ConsumerState<_PaychecksListTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> rows, String search) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((row) {
      return (row['id']?.toString().toLowerCase().contains(q) ?? false) ||
          (row['driver_id']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);
  }

  StatusBadgeVariant _statusVariant(String status) {
    if (status == 'paid') return StatusBadgeVariant.success;
    if (status == 'cancelled') return StatusBadgeVariant.danger;
    return StatusBadgeVariant.warning;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'paychecks';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final filtered = _filter(widget.paychecks, controls.search);
    final pagination = _slice.call(
      filtered,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [controls.search, controls.layout.name],
      ),
    );
    final sliceOptions = adminPaginatedOptions(
      controls: controls,
      notifier: controlsNotifier,
    );

    return AdminListStack(
      children: [
        AdminManagedListToolbarSection(
          controls: controls,
          notifier: controlsNotifier,
          selection: _selection,
          onSelectionChanged: _refreshSelection,
          sortOptions: adminEntityGridSortOptions(),
        ),
        const SizedBox(height: 12),
        AdminLayoutSwitch(
          layout: controls.layout,
          isEmpty: pagination.visibleItems.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No paychecks available.'),
          ),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final status = row['status']?.toString() ?? 'pending';
                final actions = InlineRowActions(
                  onRemind: status == 'pending' && id.isNotEmpty
                      ? () => widget.onSetStatus(row, 'paid')
                      : null,
                  remindLabel: 'Mark paid',
                  onDelete: () => widget.onDelete(row),
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  leading: StatusBadge(label: status, variant: _statusVariant(status)),
                  title: Text(
                    'Driver ${row['driver_id'] ?? '—'} · \$${row['amount'] ?? '—'}',
                  ),
                  subtitle: Text('ID: ${row['id'] ?? '—'} · $status'),
                  actions: actions,
                );
              },
            ),
          ),
          grid: AdminEntityGrid(
            children: [
              for (final row in pagination.visibleItems)
                AdminEntityGridCard(
                  selected: _selection.isSelected(rowId(row)),
                  onTap: () {
                    _selection.toggle(rowId(row));
                    _refreshSelection();
                  },
                  selection: AdminListSelectCheckbox(compact: true, 
                    checked: _selection.isSelected(rowId(row)),
                    onChanged: () {
                      _selection.toggle(rowId(row));
                      _refreshSelection();
                    },
                  ),
                  child: Text('Driver ${row['driver_id'] ?? '—'}'),
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
  }
}

class _DriverEarningsTab extends ConsumerStatefulWidget {
  const _DriverEarningsTab({required this.earnings, required this.onRefresh});

  final List<Map<String, dynamic>> earnings;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends ConsumerState<_DriverEarningsTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'driver_earnings';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final pagination = _slice.call(
      widget.earnings,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [controls.layout.name],
      ),
    );
    final sliceOptions = adminPaginatedOptions(
      controls: controls,
      notifier: controlsNotifier,
    );

    return AdminListStack(
      children: [
        AdminManagedListToolbarSection(
          controls: controls,
          notifier: controlsNotifier,
          selection: _selection,
          onSelectionChanged: _refreshSelection,
          sortOptions: adminEntityGridSortOptions(),
        ),
        const SizedBox(height: 12),
        AdminLayoutSwitch(
          layout: controls.layout,
          isEmpty: pagination.visibleItems.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No driver earnings available.'),
          ),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final actions = InlineRowActions(
                  onView: () async {
                    final ok = await showDriverEarningActionsSheet(context, ref, row);
                    if (ok == true) await widget.onRefresh();
                  },
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  title: Text(
                    row['driver_email']?.toString() ??
                        row['driver_id']?.toString() ??
                        'Driver',
                  ),
                  subtitle: Text(
                    'Balance: \$${row['balance'] ?? row['available'] ?? '—'}',
                  ),
                  actions: actions,
                );
              },
            ),
          ),
          grid: AdminEntityGrid(
            children: [
              for (final row in pagination.visibleItems)
                AdminEntityGridCard(
                  selected: _selection.isSelected(rowId(row)),
                  onTap: () {
                    _selection.toggle(rowId(row));
                    _refreshSelection();
                  },
                  selection: AdminListSelectCheckbox(compact: true, 
                    checked: _selection.isSelected(rowId(row)),
                    onChanged: () {
                      _selection.toggle(rowId(row));
                      _refreshSelection();
                    },
                  ),
                  child: Text(
                    row['driver_email']?.toString() ??
                        row['driver_id']?.toString() ??
                        'Driver',
                  ),
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
  }
}

class _PaychecksPayload {
  const _PaychecksPayload({required this.paychecks, required this.earnings});

  final Map<String, dynamic> paychecks;
  final Map<String, dynamic> earnings;
}
