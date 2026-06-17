import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/components/admin/create_task_sheet.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminSettingsTasksPage extends ConsumerStatefulWidget {
  const AdminSettingsTasksPage({super.key});

  @override
  ConsumerState<AdminSettingsTasksPage> createState() =>
      _AdminSettingsTasksPageState();
}

class _AdminSettingsTasksPageState extends ConsumerState<AdminSettingsTasksPage> {
  Future<Map<String, dynamic>>? _future;
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

  Future<Map<String, dynamic>> _load() {
    return tasksService.list(ref.read(authProvider).accessToken);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _runTask(String id) async {
    await tasksService.run(ref.read(authProvider).accessToken, id);
    await _refresh();
  }

  Future<void> _togglePause(Map<String, dynamic> task) async {
    final id = task['id']?.toString() ?? '';
    final pausedAt = task['paused_at']?.toString();
    if (pausedAt == null || pausedAt.isEmpty) {
      await tasksService.pause(ref.read(authProvider).accessToken, id);
    } else {
      await tasksService.resume(ref.read(authProvider).accessToken, id);
    }
    await _refresh();
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final id = task['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${task['name'] ?? id}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await tasksService.removeTask(ref.read(authProvider).accessToken, id);
    await _refresh();
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> tasks,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var filtered = tasks.where((task) {
      final paused = (task['paused_at']?.toString() ?? '').isNotEmpty;
      if (_statusFilter == 'active' && paused) return false;
      if (_statusFilter == 'paused' && !paused) return false;
      if (q.isEmpty) return true;
      return (task['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (task['task_key']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      filtered = [...filtered]
        ..sort((a, b) {
          if (sort.key == 'name') {
            return compareSortable(a['name'], b['name'], sort.dir);
          }
          return compareSortable(a['updated_at'], b['updated_at'], sort.dir);
        });
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'tasks';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return PermissionGate(
      permissions: const ['tasks:read', 'settings:read'],
      fallback: const Center(child: Text('No access to scheduled tasks.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Tasks',
              subtitle: 'Create, run, pause, and delete scheduled admin tasks.',
              action: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showCreateTaskSheet(context, ref, onCreated: _refresh),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New task'),
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
                      child: Text('Failed to load tasks: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final raw = snapshot.data?['tasks'];
                final tasks = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];
                final filtered = _filterAndSort(tasks, controls);
                final pagination = _slice.call(
                  filtered,
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
                final active = tasks.where((t) => (t['paused_at']?.toString() ?? '').isEmpty).length;
                final paused = tasks.length - active;

                return AdminListStack(
                  children: [
                    AdminCollapsibleOverview(
                      summary: '${tasks.length} planned · $active active · $paused paused',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            label: 'Planned',
                            value: '${tasks.length}',
                            icon: Icons.list_alt,
                          ),
                          AdminStatCard(
                            label: 'Active',
                            value: '$active',
                            icon: Icons.play_circle_outline,
                            tone: AdminStatTone.success,
                          ),
                          AdminStatCard(
                            label: 'Paused',
                            value: '$paused',
                            icon: Icons.pause_circle_outline,
                            tone: AdminStatTone.warning,
                          ),
                        ],
                      ),
                    ),
                    AdminSearchToolbar(
                      value: controls.search,
                      onChanged: controlsNotifier.setSearch,
                      placeholder: 'Search tasks',
                    ),
                    const SizedBox(height: 10),
                    AdminManagedListToolbarSection(
                      controls: controls,
                      notifier: controlsNotifier,
                      selection: _selection,
                      onSelectionChanged: _refreshSelection,
                      sortOptions: adminEntityGridSortOptions(defaultKey: 'name'),
                      filters: AdminFilterSelect(
                        value: _statusFilter,
                        onChanged: (v) => setState(() => _statusFilter = v),
                        options: const [
                          AdminFilterOption(value: 'all', label: 'All'),
                          AdminFilterOption(value: 'active', label: 'Active'),
                          AdminFilterOption(value: 'paused', label: 'Paused'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminLayoutSwitch(
                      layout: controls.layout,
                      isEmpty: pagination.visibleItems.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No scheduled tasks found.'),
                      ),
                      table: AdminTableCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagination.visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final task = pagination.visibleItems[index];
                            final id = rowId(task);
                            final isPaused =
                                (task['paused_at']?.toString() ?? '').isNotEmpty;
                            final actions = InlineRowActions(
                              onRemind: id.isEmpty ? null : () => _runTask(id),
                              remindLabel: 'Run now',
                              onToggle: () => _togglePause(task),
                              profileLabel: isPaused ? 'Resume' : 'Pause',
                              onDelete: () => _deleteTask(task),
                            );

                            return AdminSelectableListTile(
                              id: id,
                              selected: _selection.isSelected(id),
                              onToggleSelected: () {
                                _selection.toggle(id);
                                _refreshSelection();
                              },
                              leading: StatusBadge(
                                label: isPaused ? 'Paused' : 'Active',
                                variant: isPaused
                                    ? StatusBadgeVariant.warning
                                    : StatusBadgeVariant.success,
                              ),
                              title: Text(task['name']?.toString() ?? 'Task'),
                              subtitle: Text(
                                'Key: ${task['task_key'] ?? '—'} · Next: ${task['next_run_at'] ?? '—'} · Last: ${task['last_status'] ?? '—'}',
                              ),
                              actions: actions,
                            );
                          },
                        ),
                      ),
                      grid: AdminEntityGrid(
                        children: [
                          for (final task in pagination.visibleItems)
                            _TaskGridCard(
                              task: task,
                              selected: _selection.isSelected(rowId(task)),
                              onToggleSelected: () {
                                _selection.toggle(rowId(task));
                                _refreshSelection();
                              },
                              onRun: _runTask,
                              onTogglePause: _togglePause,
                              onDelete: _deleteTask,
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

class _TaskGridCard extends StatelessWidget {
  const _TaskGridCard({
    required this.task,
    required this.selected,
    required this.onToggleSelected,
    required this.onRun,
    required this.onTogglePause,
    required this.onDelete,
  });

  final Map<String, dynamic> task;
  final bool selected;
  final VoidCallback onToggleSelected;
  final Future<void> Function(String id) onRun;
  final Future<void> Function(Map<String, dynamic>) onTogglePause;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  Widget build(BuildContext context) {
    final id = rowId(task);
    final isPaused = (task['paused_at']?.toString() ?? '').isNotEmpty;
    final actions = InlineRowActions(
      onRemind: id.isEmpty ? null : () => onRun(id),
      remindLabel: 'Run now',
      onToggle: () => onTogglePause(task),
      profileLabel: isPaused ? 'Resume' : 'Pause',
      onDelete: () => onDelete(task),
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
          Text(task['name']?.toString() ?? 'Task', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          StatusBadge(
            label: isPaused ? 'Paused' : 'Active',
            variant: isPaused ? StatusBadgeVariant.warning : StatusBadgeVariant.success,
          ),
          const SizedBox(height: 6),
          Text(
            task['task_key']?.toString() ?? '—',
            style: Theme.of(context).textTheme.bodySmall,
          ),
                  ],
      ),
    );
  }
}
