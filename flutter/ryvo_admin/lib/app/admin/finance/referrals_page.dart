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

class FinanceReferralsPage extends ConsumerStatefulWidget {
  const FinanceReferralsPage({super.key});

  @override
  ConsumerState<FinanceReferralsPage> createState() =>
      _FinanceReferralsPageState();
}

class _FinanceReferralsPageState extends ConsumerState<FinanceReferralsPage> {
  Future<_ReferralsPayload>? _future;
  String _bonusAudience = 'clients';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReferralsPayload> _load() async {
    final token = ref.read(authProvider).accessToken;
    final referrals = await financeService.getReferrals(token);
    final coupons = await financeService.getCoupons(token);
    final settings = await financeService.getReferralSettings(token);
    return _ReferralsPayload(
      referrals: referrals,
      coupons: coupons,
      settings: settings,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<Map<String, dynamic>> _bonuses(_ReferralsPayload data) {
    final isDriver = _bonusAudience == 'drivers';
    final key = isDriver ? 'driverBonuses' : 'clientBonuses';
    return financeRows(data.referrals, keys: [key, 'bonuses']);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:referrals:read', 'payments:read'],
      fallback: const Center(
        child: Text('You do not have access to referrals finance module.'),
      ),
      child: DefaultTabController(
        length: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_ReferralsPayload>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text('Failed to load referrals hub: ${snapshot.error}');
              }
              final data = snapshot.data!;
              final coupons = financeRows(data.coupons, keys: const ['coupons']);
              final campaigns = financeRows(
                data.referrals,
                keys: const ['campaigns', 'programs'],
              );
              final bonuses = _bonuses(data);
              final settings = data.settings['settings'] is Map
                  ? Map<String, dynamic>.from(data.settings['settings'] as Map)
                  : data.settings;

              return AdminListStack(
                children: [
                  AdminPageHeader(
                    title: 'Referrals',
                    subtitle: 'Bonus, coupons, referral programs, and referral settings.',
                    action: OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Bonus'),
                      Tab(text: 'Coupons'),
                      Tab(text: 'Referrals'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _BonusTab(
                          rows: bonuses,
                          audience: _bonusAudience,
                          onAudienceChanged: (v) => setState(() => _bonusAudience = v),
                          onRefresh: _refresh,
                        ),
                        _CouponsTab(rows: coupons, onRefresh: _refresh),
                        _CampaignsTab(rows: campaigns, onRefresh: _refresh),
                        _SettingsTab(settings: settings, onRefresh: _refresh),
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

class _ReferralsPayload {
  const _ReferralsPayload({
    required this.referrals,
    required this.coupons,
    required this.settings,
  });

  final Map<String, dynamic> referrals;
  final Map<String, dynamic> coupons;
  final Map<String, dynamic> settings;
}

class _BonusTab extends ConsumerStatefulWidget {
  const _BonusTab({
    required this.rows,
    required this.audience,
    required this.onAudienceChanged,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> rows;
  final String audience;
  final ValueChanged<String> onAudienceChanged;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_BonusTab> createState() => _BonusTabState();
}

class _BonusTabState extends ConsumerState<_BonusTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> _sortRows(ListControlsState controls) {
    final sort = controls.activeSort;
    if (sort == null) return widget.rows;
    final rows = [...widget.rows];
    rows.sort((a, b) => compareSortable(a['updated_at'], b['updated_at'], sort.dir));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'referral_bonuses';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final rows = _sortRows(controls);
    final pagination = _slice.call(
      rows,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [widget.audience, controls.layout.name],
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
            ChoiceChip(
              label: const Text('Clients'),
              selected: widget.audience == 'clients',
              onSelected: (_) => widget.onAudienceChanged('clients'),
            ),
            ChoiceChip(
              label: const Text('Drivers'),
              selected: widget.audience == 'drivers',
              onSelected: (_) => widget.onAudienceChanged('drivers'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showBonusEditorSheet(
                  context,
                  ref,
                  isDriver: widget.audience == 'drivers',
                );
                if (ok == true) widget.onRefresh();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add bonus'),
            ),
          ],
        ),
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
          empty: const Padding(padding: EdgeInsets.all(16), child: Text('No bonuses found.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final actions = InlineRowActions(
                  onEdit: () async {
                    final ok = await showBonusEditorSheet(
                      context,
                      ref,
                      existing: row,
                      isDriver: widget.audience == 'drivers',
                    );
                    if (ok == true) widget.onRefresh();
                  },
                  onDelete: () async {
                    final ok = await confirmDelete(context, title: 'Delete bonus?');
                    if (!ok) return;
                    await financeService.deleteBonus(
                      ref.read(authProvider).accessToken,
                      id,
                    );
                    widget.onRefresh();
                  },
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  title: Text(row['email']?.toString() ?? 'Bonus account'),
                  subtitle: Text(
                    'Balance: \$${row['balance'] ?? 0} · Channel: ${row['channel'] ?? '—'}',
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
                  child: Text(row['email']?.toString() ?? 'Bonus account'),
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

class _CouponsTab extends ConsumerStatefulWidget {
  const _CouponsTab({required this.rows, required this.onRefresh});

  final List<Map<String, dynamic>> rows;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends ConsumerState<_CouponsTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'referral_coupons';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final pagination = _slice.call(
      widget.rows,
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
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await showCouponEditorSheet(context, ref);
              if (ok == true) widget.onRefresh();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New coupon'),
          ),
        ),
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
          empty: const Padding(padding: EdgeInsets.all(16), child: Text('No coupons found.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final active = row['active'] == true;
                final actions = InlineRowActions(
                  onEdit: () async {
                    final ok = await showCouponEditorSheet(context, ref, existing: row);
                    if (ok == true) widget.onRefresh();
                  },
                  onDelete: () async {
                    final ok = await confirmDelete(context, title: 'Delete coupon?');
                    if (!ok) return;
                    await financeService.deleteCoupon(
                      ref.read(authProvider).accessToken,
                      id,
                    );
                    widget.onRefresh();
                  },
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
                  title: Text(row['code']?.toString() ?? 'Coupon'),
                  subtitle: Text('Bonus: \$${row['bonus_cad'] ?? 0}'),
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
                  child: Text(row['code']?.toString() ?? 'Coupon'),
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

class _CampaignsTab extends ConsumerStatefulWidget {
  const _CampaignsTab({required this.rows, required this.onRefresh});

  final List<Map<String, dynamic>> rows;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends ConsumerState<_CampaignsTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'referral_campaigns';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final pagination = _slice.call(
      widget.rows,
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
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _showCampaignSheet(context, ref, onRefresh: widget.onRefresh),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New campaign'),
          ),
        ),
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
          empty: const Padding(padding: EdgeInsets.all(16), child: Text('No campaigns found.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final actions = InlineRowActions(
                  onDelete: () async {
                    final ok = await confirmDelete(context, title: 'Delete campaign?');
                    if (!ok) return;
                    await financeService.deleteCampaign(
                      ref.read(authProvider).accessToken,
                      id,
                    );
                    widget.onRefresh();
                  },
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  title: Text(row['name']?.toString() ?? 'Campaign'),
                  subtitle: Text('Goal: ${row['goal'] ?? '—'} · Reward: ${row['reward_cad'] ?? '—'}'),
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
                  child: Text(row['name']?.toString() ?? 'Campaign'),
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

  Future<void> _showCampaignSheet(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onRefresh,
  }) async {
    final nameCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '5');
    final rewardCtrl = TextEditingController(text: '10');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
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
            Text('New campaign', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Goal (referrals)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rewardCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reward (CAD)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                try {
                  await financeService.createCampaign(
                    ref.read(authProvider).accessToken,
                    {
                      'name': nameCtrl.text.trim(),
                      'goal': int.tryParse(goalCtrl.text.trim()) ?? 5,
                      'reward_cad': num.tryParse(rewardCtrl.text.trim()) ?? 10,
                      'audience': 'clients',
                    },
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create campaign'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) onRefresh();
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab({required this.settings, required this.onRefresh});

  final Map<String, dynamic> settings;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final entry in widget.settings.entries)
        entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        final raw = entry.value.text.trim();
        body[entry.key] = num.tryParse(raw) ?? raw;
      }
      await financeService.updateReferralSettings(
        ref.read(authProvider).accessToken,
        body,
      );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral settings saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) {
      return const AdminTableCard(
        isEmpty: true,
        empty: Padding(padding: EdgeInsets.all(16), child: Text('No settings found.')),
        child: SizedBox.shrink(),
      );
    }
    return AdminListStack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final entry in _controllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save settings'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
