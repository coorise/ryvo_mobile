import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminSettingsTasksPage extends ConsumerStatefulWidget {
  const AdminSettingsTasksPage({super.key});

  @override
  ConsumerState<AdminSettingsTasksPage> createState() =>
      _AdminSettingsTasksPageState();
}

class _AdminSettingsTasksPageState
    extends ConsumerState<AdminSettingsTasksPage> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = tasksService.list(useAuth(ref).accessToken);
  }

  Future<void> _refresh() async {
    setState(() => _future = tasksService.list(useAuth(ref).accessToken));
    await _future;
  }

  Future<void> _runTask(String id) async {
    await tasksService.run(useAuth(ref).accessToken, id);
    await _refresh();
  }

  Future<void> _togglePause(Map<String, dynamic> task) async {
    final id = task['id']?.toString() ?? '';
    final pausedAt = task['paused_at']?.toString();
    if (pausedAt == null || pausedAt.isEmpty) {
      await tasksService.pause(useAuth(ref).accessToken, id);
    } else {
      await tasksService.resume(useAuth(ref).accessToken, id);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['tasks:read', 'settings:read'],
      fallback: const Center(child: Text('No access to scheduled tasks.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Tasks',
              subtitle: 'Cron and scheduled admin tasks.',
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

                return AdminTableCard(
                  isEmpty: tasks.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No scheduled tasks found.'),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final paused =
                          (task['paused_at']?.toString() ?? '').isNotEmpty;
                      return ListTile(
                        title: Text(task['name']?.toString() ?? 'Task'),
                        subtitle: Text(
                          'Key: ${task['task_key'] ?? '—'} · Next run: ${task['next_run_at'] ?? '—'} · Last: ${task['last_status'] ?? '—'}',
                        ),
                        leading: StatusBadge(
                          label: paused ? 'Paused' : 'Active',
                          variant: paused
                              ? StatusBadgeVariant.warning
                              : StatusBadgeVariant.success,
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _runTask(task['id']?.toString() ?? ''),
                              child: const Text('Run'),
                            ),
                            OutlinedButton(
                              onPressed: () => _togglePause(task),
                              child: Text(paused ? 'Resume' : 'Pause'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
