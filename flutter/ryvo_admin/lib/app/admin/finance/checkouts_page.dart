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

class FinanceCheckoutsPage extends ConsumerStatefulWidget {
  const FinanceCheckoutsPage({super.key});

  @override
  ConsumerState<FinanceCheckoutsPage> createState() =>
      _FinanceCheckoutsPageState();
}

class _FinanceCheckoutsPageState extends ConsumerState<FinanceCheckoutsPage> {
  Future<List<Map<String, dynamic>>>? _future;
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _statusFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = ref.read(authProvider).accessToken;
    final status = _statusFilter == 'all' ? null : _statusFilter;
    final json = await financeService.getCheckouts(token, status: status);
    return financeRows(json, keys: const ['checkouts']);
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
    var filtered = q.isEmpty
        ? rows
        : rows.where((row) {
            return (row['id']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['user_id']?.toString().toLowerCase().contains(q) ?? false) ||
                (row['email']?.toString().toLowerCase().contains(q) ?? false);
          }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      filtered = [...filtered]
        ..sort((a, b) {
          if (sort.key == 'status') {
            return compareSortable(a['status'], b['status'], sort.dir);
          }
          return compareSortable(a['updated_at'], b['updated_at'], sort.dir);
        });
    }
    return filtered;
  }

  Future<void> _deleteCheckout(String id) async {
    final ok = await confirmDelete(context, title: 'Delete checkout record?');
    if (!ok) return;
    await financeService.deleteCheckout(ref.read(authProvider).accessToken, id);
    await _refresh();
  }

  void _showPreview(Map<String, dynamic> row) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Checkout ${row['id'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: row.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${e.key}: ${e.value}'),
                    ))
                .toList(growable: false),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  StatusBadgeVariant _statusVariant(String status) {
    if (status == 'failed') return StatusBadgeVariant.danger;
    if (status == 'completed') return StatusBadgeVariant.success;
    return StatusBadgeVariant.warning;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'checkouts';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const [
        'finances:checkouts:read',
        'finances:checkouts:update',
        'payments:read',
      ],
      fallback: const Center(child: Text('You do not have access to checkout recovery.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Checkouts Recovery',
              subtitle: 'Pending and failed checkouts with recovery reminders.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminSearchToolbar(
              value: controls.search,
              onChanged: controlsNotifier.setSearch,
              placeholder: 'Search checkouts',
            ),
            const SizedBox(height: 10),
            AdminManagedListToolbarSection(
              controls: controls,
              notifier: controlsNotifier,
              selection: _selection,
              onSelectionChanged: _refreshSelection,
              sortOptions: adminEntityGridSortOptions(),
              filters: AdminFilterSelect(
                value: _statusFilter,
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _refresh();
                },
                options: const [
                  AdminFilterOption(value: 'all', label: 'All'),
                  AdminFilterOption(value: 'pending', label: 'Pending'),
                  AdminFilterOption(value: 'failed', label: 'Failed'),
                  AdminFilterOption(value: 'completed', label: 'Completed'),
                ],
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Failed to load checkouts: ${snapshot.error}');
                }
                final rows = _filterAndSort(snapshot.data ?? const [], controls);
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
                final sliceOptions = adminPaginatedOptions(
                  controls: controls,
                  notifier: controlsNotifier,
                );

                return AdminListStack(
                  children: [
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No checkout records found.'),
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
                              onView: () => _showPreview(row),
                              onRemind: id.isEmpty
                                  ? null
                                  : () async {
                                      final ok = await showCheckoutRecoverySheet(
                                        context,
                                        ref,
                                        id,
                                      );
                                      if (ok == true) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Recovery reminder scheduled.'),
                                          ),
                                        );
                                        await _refresh();
                                      }
                                    },
                              remindLabel: 'Recover',
                              onDelete: id.isEmpty ? null : () => _deleteCheckout(id),
                            );

                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              leading: StatusBadge(
                                label: status,
                                variant: _statusVariant(status),
                              ),
                              title: Text(id.isEmpty ? 'Checkout' : id),
                              subtitle: Text(
                                'User: ${row['user_id'] ?? row['email'] ?? '—'} · Amount: ${row['amount'] ?? row['fare'] ?? '—'}',
                              ),
                              actions: actions,
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final row in pagination.visibleItems)
                            _CheckoutGridCard(
                              row: row,
                              selected: _selection.isSelected(rowId(row)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(row));
                                _refreshSelection();
                              },
                              onPreview: _showPreview,
                              onRecover: (id) async {
                                final ok = await showCheckoutRecoverySheet(context, ref, id);
                                if (ok == true) await _refresh();
                              },
                              onDelete: _deleteCheckout,
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

class _CheckoutGridCard extends StatelessWidget {
  const _CheckoutGridCard({
    required this.row,
    required this.selected,
    required this.onToggleSelected,
    required this.onPreview,
    required this.onRecover,
    required this.onDelete,
    required this.statusVariant,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final VoidCallback onToggleSelected;
  final void Function(Map<String, dynamic>) onPreview;
  final Future<void> Function(String id) onRecover;
  final Future<void> Function(String id) onDelete;
  final StatusBadgeVariant Function(String) statusVariant;

  @override
  Widget build(BuildContext context) {
    final id = rowId(row);
    final status = row['status']?.toString() ?? 'unknown';
    final actions = InlineRowActions(
      onView: () => onPreview(row),
      onRemind: id.isEmpty ? null : () => onRecover(id),
      remindLabel: 'Recover',
      onDelete: id.isEmpty ? null : () => onDelete(id),
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
          Text(id.isEmpty ? 'Checkout' : id, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          StatusBadge(label: status, variant: statusVariant(status)),
          const SizedBox(height: 6),
          Text(
            '${row['user_id'] ?? row['email'] ?? '—'} · ${row['amount'] ?? row['fare'] ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
                  ],
      ),
    );
  }
}
