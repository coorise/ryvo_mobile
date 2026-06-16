import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminMessagesPage extends ConsumerStatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  ConsumerState<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends ConsumerState<AdminMessagesPage> {
  Future<Map<String, dynamic>>? _future;
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _statusFilter = 'all';
  String _audienceFilter = 'all_audiences';

  void _refreshSelection() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() {
    final token = ref.read(authProvider).accessToken;
    return messagesService.list(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _deleteCampaign(Map<String, dynamic> campaign) async {
    final id = campaign['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete campaign?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await messagesService.remove(ref.read(authProvider).accessToken, id);
    if (mounted) await _refresh();
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> source,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var rows = source.where((row) {
      final status = row['status']?.toString() ?? '';
      final audience = row['audience']?.toString() ?? '';
      final body = row['body_template']?.toString() ?? '';
      final id = row['id']?.toString() ?? '';
      if (_statusFilter != 'all' && status != _statusFilter) return false;
      if (_audienceFilter == 'clients' && audience != 'clients') return false;
      if (_audienceFilter == 'drivers' && audience != 'drivers') return false;
      if (_audienceFilter == 'everyone' && audience != 'all') return false;
      if (q.isEmpty) return true;
      return body.toLowerCase().contains(q) ||
          id.toLowerCase().contains(q) ||
          status.toLowerCase().contains(q);
    }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      rows = [...rows]
        ..sort((a, b) {
          if (sort.key == 'status') {
            return compareSortable(a['status'], b['status'], sort.dir);
          }
          return compareSortable(a['created_at'], b['created_at'], sort.dir);
        });
    }
    return rows;
  }

  int _countByStatus(List<Map<String, dynamic>> rows, String status) {
    return rows.where((r) => r['status']?.toString() == status).length;
  }

  StatusBadgeVariant _statusVariant(String status) {
    if (status == 'sent') return StatusBadgeVariant.success;
    if (status == 'queued') return StatusBadgeVariant.info;
    if (status == 'draft') return StatusBadgeVariant.warning;
    return StatusBadgeVariant.danger;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'messages';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const ['communication:messages:read', 'support:reply'],
      fallback: const Center(child: Text('No access to campaigns.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Messages',
              subtitle: 'Message campaigns list.',
              action: Wrap(
                spacing: 8,
                children: [
                  ShadButton(
                    onPressed: () => context.go(Routes.adminCommMessagesNew),
                    child: const Text('Compose'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
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
                      child: Text(
                        'Failed to load campaigns: ${snapshot.error}',
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final campaignsRaw = snapshot.data?['campaigns'];
                final campaigns = campaignsRaw is List
                    ? campaignsRaw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(growable: false)
                    : <Map<String, dynamic>>[];
                final rows = _filterAndSort(campaigns, controls);
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
                      _audienceFilter,
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
                    AdminCollapsibleOverview(
                      summary:
                          '${campaigns.length} total · ${_countByStatus(campaigns, 'draft')} drafts · ${_countByStatus(campaigns, 'sent')} sent',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            label: 'Total',
                            value: '${campaigns.length}',
                            icon: Icons.message_outlined,
                          ),
                          AdminStatCard(
                            label: 'Drafts',
                            value: '${_countByStatus(campaigns, 'draft')}',
                            icon: Icons.edit_note,
                            tone: AdminStatTone.warning,
                          ),
                          AdminStatCard(
                            label: 'Sent',
                            value: '${_countByStatus(campaigns, 'sent')}',
                            icon: Icons.send,
                            tone: AdminStatTone.success,
                          ),
                          AdminStatCard(
                            label: 'Queued',
                            value: '${_countByStatus(campaigns, 'queued')}',
                            icon: Icons.schedule_send,
                            tone: AdminStatTone.info,
                          ),
                        ],
                      ),
                    ),
                    AdminSearchToolbar(
                      value: controls.search,
                      onChanged: controlsNotifier.setSearch,
                      placeholder: 'Search campaigns',
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
                      filters: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AdminFilterSelect(
                            value: _statusFilter,
                            onChanged: (v) => setState(() => _statusFilter = v),
                            options: const [
                              AdminFilterOption(value: 'all', label: 'All statuses'),
                              AdminFilterOption(value: 'draft', label: 'Draft'),
                              AdminFilterOption(value: 'queued', label: 'Queued'),
                              AdminFilterOption(value: 'sent', label: 'Sent'),
                              AdminFilterOption(value: 'cancelled', label: 'Cancelled'),
                            ],
                          ),
                          AdminFilterSelect(
                            value: _audienceFilter,
                            onChanged: (v) => setState(() => _audienceFilter = v),
                            options: const [
                              AdminFilterOption(value: 'all_audiences', label: 'All audiences'),
                              AdminFilterOption(value: 'clients', label: 'Clients'),
                              AdminFilterOption(value: 'drivers', label: 'Drivers'),
                              AdminFilterOption(value: 'everyone', label: 'Everyone'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No campaigns found for the selected filters.'),
                      ),
                      table: AdminTableCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagination.visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = pagination.visibleItems[index];
                            final id = rowId(c);
                            final status = c['status']?.toString() ?? 'unknown';
                            final audience = c['audience']?.toString() ?? 'unknown';
                            final createdAt = c['created_at']?.toString() ?? '—';
                            final isDraft = status == 'draft';
                            final actions = InlineRowActions(
                              onEdit: id.isEmpty
                                  ? null
                                  : () => context.go('/admin/communication/messages/$id/edit'),
                              onDelete: isDraft && id.isNotEmpty
                                  ? () => _deleteCampaign(c)
                                  : null,
                            );

                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              onTap: id.isEmpty
                                  ? null
                                  : () => context.go('/admin/communication/messages/$id/edit'),
                              leading: StatusBadge(
                                label: status,
                                variant: _statusVariant(status),
                              ),
                              title: Text(
                                c['body_template']?.toString() ?? '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('Audience: $audience · Created: $createdAt'),
                              actions: actions,
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final c in pagination.visibleItems)
                            _CampaignGridCard(
                              campaign: c,
                              selected: _selection.isSelected(rowId(c)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(c));
                                _refreshSelection();
                              },
                              onDelete: _deleteCampaign,
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

class _CampaignGridCard extends StatelessWidget {
  const _CampaignGridCard({
    required this.campaign,
    required this.selected,
    required this.onToggleSelected,
    required this.onDelete,
    required this.statusVariant,
  });

  final Map<String, dynamic> campaign;
  final bool selected;
  final VoidCallback onToggleSelected;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final StatusBadgeVariant Function(String) statusVariant;

  @override
  Widget build(BuildContext context) {
    final id = rowId(campaign);
    final status = campaign['status']?.toString() ?? 'unknown';
    final isDraft = status == 'draft';
    final actions = InlineRowActions(
      onEdit: id.isEmpty
          ? null
          : () => context.go('/admin/communication/messages/$id/edit'),
      onDelete: isDraft && id.isNotEmpty ? () => onDelete(campaign) : null,
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
          Text(
            campaign['body_template']?.toString() ?? '—',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          StatusBadge(label: status, variant: statusVariant(status)),
          const SizedBox(height: 6),
          Text(
            'Audience: ${campaign['audience'] ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
                  ],
      ),
    );
  }
}
