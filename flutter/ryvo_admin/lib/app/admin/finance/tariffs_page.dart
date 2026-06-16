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

class FinanceTariffsPage extends ConsumerStatefulWidget {
  const FinanceTariffsPage({super.key});

  @override
  ConsumerState<FinanceTariffsPage> createState() => _FinanceTariffsPageState();
}

class _FinanceTariffsPageState extends ConsumerState<FinanceTariffsPage> {
  Future<_TariffsPayload>? _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TariffsPayload> _load() async {
    final token = ref.read(authProvider).accessToken;
    final tariffs = await financeService.getTariffs(token);
    final subscribers = await financeService.getTariffSubscriptions(token);
    return _TariffsPayload(tariffs: tariffs, subscribers: subscribers);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> rows) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((row) {
      return (row['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (row['code']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);
  }

  Future<void> _deleteTariff(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await confirmDelete(context, title: 'Delete tariff?');
    if (!ok) return;
    await financeService.deleteTariff(ref.read(authProvider).accessToken, id);
    await _refresh();
  }

  Future<void> _toggleActive(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final body = Map<String, dynamic>.from(row);
    body['active'] = row['active'] != true;
    await financeService.updateTariff(ref.read(authProvider).accessToken, id, body);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:tariffs:read', 'payments:read'],
      fallback: const Center(child: Text('You do not have access to tariffs.')),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_TariffsPayload>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text('Failed to load tariffs: ${snapshot.error}');
              }
              final data = snapshot.data!;
              final packages = financeRows(
                data.tariffs,
                keys: const ['packages', 'tariffs'],
              );
              final subscribers = financeRows(
                data.subscribers,
                keys: const ['subscriptions'],
              );
              final filteredPackages = _filter(packages);

              return AdminListStack(
                children: [
                  AdminPageHeader(
                    title: 'Tariffs',
                    subtitle: 'Tariff definitions and active subscriptions.',
                    action: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showTariffEditorSheet(context, ref);
                            if (ok == true) await _refresh();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New tariff'),
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
                    value: _search,
                    onChanged: (v) => setState(() => _search = v),
                    placeholder: 'Search tariffs',
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Tariffs'),
                      Tab(text: 'Subscribers'),
                    ],
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _TariffsListTab(
                          packages: filteredPackages,
                          onRefresh: _refresh,
                          onToggleActive: _toggleActive,
                          onDelete: _deleteTariff,
                        ),
                        _SubscribersTab(
                          subscribers: subscribers,
                          packages: packages.where((p) => p['active'] == true).toList(),
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

class _TariffsListTab extends ConsumerStatefulWidget {
  const _TariffsListTab({
    required this.packages,
    required this.onRefresh,
    required this.onToggleActive,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> packages;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>) onToggleActive;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  ConsumerState<_TariffsListTab> createState() => _TariffsListTabState();
}

class _TariffsListTabState extends ConsumerState<_TariffsListTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> _sortRows(ListControlsState controls) {
    final sort = controls.activeSort;
    if (sort == null) return widget.packages;
    final rows = [...widget.packages];
    rows.sort((a, b) {
      if (sort.key == 'name') {
        return compareSortable(a['name'], b['name'], sort.dir);
      }
      return compareSortable(a['updated_at'], b['updated_at'], sort.dir);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'tariffs';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final rows = _sortRows(controls);
    final pagination = _slice.call(
      rows,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [controls.activeSort?.key, controls.activeSort?.dir.name, controls.layout.name],
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
          sortOptions: adminEntityGridSortOptions(defaultKey: 'name'),
        ),
        const SizedBox(height: 12),
        AdminLayoutSwitch(
          layout: controls.layout,
          isEmpty: pagination.visibleItems.isEmpty,
          empty: const Padding(padding: EdgeInsets.all(16), child: Text('No tariffs found.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final active = row['active'] == true;
                final actions = InlineRowActions(
                  onToggle: () => widget.onToggleActive(row),
                  profileLabel: active ? 'Deactivate' : 'Activate',
                  onEdit: () async {
                    final ok = await showTariffEditorSheet(context, ref, existing: row);
                    if (ok == true) await widget.onRefresh();
                  },
                  onDelete: () => widget.onDelete(row),
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  leading: StatusBadge(
                    label: active ? 'Active' : 'Inactive',
                    variant: active
                        ? StatusBadgeVariant.success
                        : StatusBadgeVariant.defaultVariant,
                  ),
                  title: Text(row['name']?.toString() ?? 'Tariff'),
                  subtitle: Text(
                    'Code: ${row['code'] ?? '—'} · Commission: ${row['commission_percent'] ?? '—'}%',
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
                  child: Text(row['name']?.toString() ?? 'Tariff'),
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

class _SubscribersTab extends ConsumerStatefulWidget {
  const _SubscribersTab({
    required this.subscribers,
    required this.packages,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> subscribers;
  final List<Map<String, dynamic>> packages;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_SubscribersTab> createState() => _SubscribersTabState();
}

class _SubscribersTabState extends ConsumerState<_SubscribersTab> {
  String _statusFilter = 'all';
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'all') return widget.subscribers;
    return widget.subscribers
        .where((s) => s['status']?.toString() == _statusFilter)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _sortRows(ListControlsState controls) {
    final sort = controls.activeSort;
    if (sort == null) return _filtered;
    final rows = [..._filtered];
    rows.sort((a, b) => compareSortable(a['updated_at'], b['updated_at'], sort.dir));
    return rows;
  }

  Future<void> _addSubscription() async {
    final driverCtrl = TextEditingController();
    var packageId = widget.packages.isNotEmpty
        ? widget.packages.first['id']?.toString() ?? ''
        : '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add subscriber', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: driverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver ID',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.packages.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: packageId.isEmpty ? null : packageId,
                  decoration: const InputDecoration(
                    labelText: 'Tariff package',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.packages
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id']?.toString(),
                          child: Text(p['name']?.toString() ?? 'Package'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (v) => setLocal(() => packageId = v ?? ''),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    await financeService.createTariffSubscription(
                      ref.read(authProvider).accessToken,
                      {
                        'driver_id': driverCtrl.text.trim(),
                        'tariff_package_id': packageId,
                        'notify': true,
                      },
                    );
                    if (context.mounted) Navigator.pop(context);
                    widget.onRefresh();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
                child: const Text('Create subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _migrateSubscription(Map<String, dynamic> row) async {
    var packageId = widget.packages.isNotEmpty
        ? widget.packages.first['id']?.toString() ?? ''
        : '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Migrate subscription'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: packageId.isEmpty ? null : packageId,
                decoration: const InputDecoration(
                  labelText: 'New tariff package',
                  border: OutlineInputBorder(),
                ),
                items: widget.packages
                    .map(
                      (p) => DropdownMenuItem(
                        value: p['id']?.toString(),
                        child: Text(p['name']?.toString() ?? 'Package'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (v) => setLocal(() => packageId = v ?? ''),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    await financeService.patchTariffSubscription(
                      ref.read(authProvider).accessToken,
                      row['id']?.toString() ?? '',
                      {
                        'action': 'migrate',
                        'tariff_package_id': packageId,
                        'notify': true,
                      },
                    );
                    if (context.mounted) Navigator.pop(context);
                    widget.onRefresh();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
                child: const Text('Migrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSubscription(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await confirmDelete(context, title: 'Delete subscription?');
    if (!ok) return;
    await financeService.deleteTariffSubscription(ref.read(authProvider).accessToken, id);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'tariff_subscribers';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final rows = _sortRows(controls);
    final pagination = _slice.call(
      rows,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [
          _statusFilter,
          controls.activeSort?.key,
          controls.activeSort?.dir.name,
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
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _addSubscription,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add subscriber'),
            ),
          ],
        ),
        AdminManagedListToolbarSection(
          controls: controls,
          notifier: controlsNotifier,
          selection: _selection,
          onSelectionChanged: _refreshSelection,
          sortOptions: adminEntityGridSortOptions(),
          filters: AdminFilterSelect(
            value: _statusFilter,
            onChanged: (v) => setState(() => _statusFilter = v),
            options: const [
              AdminFilterOption(value: 'all', label: 'All'),
              AdminFilterOption(value: 'active', label: 'Active'),
              AdminFilterOption(value: 'paused', label: 'Paused'),
              AdminFilterOption(value: 'cancelled', label: 'Cancelled'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminLayoutSwitch(
          layout: controls.layout,
          isEmpty: pagination.visibleItems.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No subscribers found.'),
          ),
          table: AdminTableCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final status = row['status']?.toString() ?? 'unknown';
                final actions = InlineRowActions(
                  onEdit: () => _migrateSubscription(row),
                  profileLabel: 'Migrate',
                  onDelete: id.isEmpty ? null : () => _deleteSubscription(row),
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  title: Text(
                    row['user_email']?.toString() ??
                        row['driver_id']?.toString() ??
                        row['id']?.toString() ??
                        'Subscriber',
                  ),
                  subtitle: Text(
                    'Tariff: ${row['tariff_name'] ?? row['tariff_id'] ?? '—'} · Status: $status',
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
                    row['user_email']?.toString() ??
                        row['driver_id']?.toString() ??
                        'Subscriber',
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

class _TariffsPayload {
  const _TariffsPayload({required this.tariffs, required this.subscribers});

  final Map<String, dynamic> tariffs;
  final Map<String, dynamic> subscribers;
}
