import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage> {
  Future<Map<String, dynamic>>? _future;
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _readFilter = 'all';

  void _refreshSelection() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() {
    final token = ref.read(authProvider).accessToken;
    return notificationService.getInbox(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markRead(String id) async {
    final token = ref.read(authProvider).accessToken;
    await notificationService.markRead(token, id);
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _remove(String id) async {
    final token = ref.read(authProvider).accessToken;
    await notificationService.remove(token, id);
    if (mounted) {
      await _refresh();
    }
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> rows,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var filtered = rows.where((n) {
      final readAt = n['read_at']?.toString();
      final isRead = readAt != null && readAt.isNotEmpty;
      if (_readFilter == 'unread' && isRead) return false;
      if (_readFilter == 'read' && !isRead) return false;
      if (q.isEmpty) return true;
      final payload = n['payload'] is Map
          ? Map<String, dynamic>.from(n['payload'] as Map)
          : const <String, dynamic>{};
      final title = payload['title']?.toString() ?? n['type']?.toString() ?? '';
      final body = payload['body']?.toString() ??
          payload['message']?.toString() ??
          '';
      return title.toLowerCase().contains(q) ||
          body.toLowerCase().contains(q) ||
          (n['type']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      filtered = [...filtered]
        ..sort((a, b) {
          if (sort.key == 'type') {
            return compareSortable(a['type'], b['type'], sort.dir);
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

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'notifications';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const [
        'communication:notifications:read',
        'settings:notifications:read',
        'support:read',
      ],
      fallback: const Center(child: Text('No access to notifications inbox.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Notifications',
              subtitle: 'Inbox notifications and delivery state.',
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
                      child: Text('Failed to load inbox: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final raw = snapshot.data?['notifications'];
                final notifications = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];
                final filtered = _filterAndSort(notifications, controls);
                final pagination = _slice.call(
                  filtered,
                  adminPaginatedOptions(
                    controls: controls,
                    notifier: controlsNotifier,
                    resetDeps: [
                      controls.search,
                      controls.activeSort?.key,
                      controls.activeSort?.dir.name,
                      _readFilter,
                      controls.layout.name,
                    ],
                  ),
                );
                final sliceOptions = adminPaginatedOptions(
                  controls: controls,
                  notifier: controlsNotifier,
                );
                final unread = notifications.where((n) {
                  final readAt = n['read_at']?.toString();
                  return readAt == null || readAt.isEmpty;
                }).length;

                return AdminListStack(
                  children: [
                    AdminCollapsibleOverview(
                      summary: '${notifications.length} total · $unread unread',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            label: 'Total',
                            value: '${notifications.length}',
                            icon: Icons.notifications_outlined,
                          ),
                          AdminStatCard(
                            label: 'Unread',
                            value: '$unread',
                            icon: Icons.mark_email_unread_outlined,
                            tone: AdminStatTone.info,
                          ),
                        ],
                      ),
                    ),
                    AdminSearchToolbar(
                      value: controls.search,
                      onChanged: controlsNotifier.setSearch,
                      placeholder: 'Search notifications',
                    ),
                    const SizedBox(height: 10),
                    AdminManagedListToolbarSection(
                      controls: controls,
                      notifier: controlsNotifier,
                      selection: _selection,
                      onSelectionChanged: _refreshSelection,
                      sortOptions: adminEntityGridSortOptions(),
                      filters: AdminFilterSelect(
                        value: _readFilter,
                        onChanged: (v) => setState(() => _readFilter = v),
                        options: const [
                          AdminFilterOption(value: 'all', label: 'All'),
                          AdminFilterOption(value: 'unread', label: 'Unread'),
                          AdminFilterOption(value: 'read', label: 'Read'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Inbox is empty.'),
                      ),
                      table: AdminTableCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagination.visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final n = pagination.visibleItems[index];
                            final id = rowId(n);
                            final readAt = n['read_at']?.toString();
                            final isRead = readAt != null && readAt.isNotEmpty;
                            final payload = n['payload'] is Map
                                ? Map<String, dynamic>.from(n['payload'] as Map)
                                : const <String, dynamic>{};
                            final title =
                                payload['title']?.toString() ??
                                n['type']?.toString() ??
                                'Notification';
                            final body =
                                payload['body']?.toString() ??
                                payload['message']?.toString() ??
                                payload.toString();
                            final actions = InlineRowActions(
                              onRemind: !isRead && id.isNotEmpty
                                  ? () => _markRead(id)
                                  : null,
                              remindLabel: 'Mark read',
                              onDelete: id.isNotEmpty ? () => _remove(id) : null,
                            );

                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              leading: StatusBadge(
                                label: isRead ? 'Read' : 'Unread',
                                variant: isRead
                                    ? StatusBadgeVariant.defaultVariant
                                    : StatusBadgeVariant.info,
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              actions: actions,
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final n in pagination.visibleItems)
                            _NotificationGridCard(
                              notification: n,
                              selected: _selection.isSelected(rowId(n)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(n));
                                _refreshSelection();
                              },
                              onMarkRead: _markRead,
                              onRemove: _remove,
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

class _NotificationGridCard extends StatelessWidget {
  const _NotificationGridCard({
    required this.notification,
    required this.selected,
    required this.onToggleSelected,
    required this.onMarkRead,
    required this.onRemove,
  });

  final Map<String, dynamic> notification;
  final bool selected;
  final VoidCallback onToggleSelected;
  final Future<void> Function(String id) onMarkRead;
  final Future<void> Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final id = rowId(notification);
    final readAt = notification['read_at']?.toString();
    final isRead = readAt != null && readAt.isNotEmpty;
    final payload = notification['payload'] is Map
        ? Map<String, dynamic>.from(notification['payload'] as Map)
        : const <String, dynamic>{};
    final title =
        payload['title']?.toString() ??
        notification['type']?.toString() ??
        'Notification';
    final body =
        payload['body']?.toString() ??
        payload['message']?.toString() ??
        '';
    final actions = InlineRowActions(
      onRemind: !isRead && id.isNotEmpty ? () => onMarkRead(id) : null,
      remindLabel: 'Mark read',
      onDelete: id.isNotEmpty ? () => onRemove(id) : null,
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
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          StatusBadge(
            label: isRead ? 'Read' : 'Unread',
            variant: isRead
                ? StatusBadgeVariant.defaultVariant
                : StatusBadgeVariant.info,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
                  ],
      ),
    );
  }
}
