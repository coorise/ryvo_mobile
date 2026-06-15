import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminAuditPage extends ConsumerStatefulWidget {
  const AdminAuditPage({super.key});

  @override
  ConsumerState<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends ConsumerState<AdminAuditPage> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = auditService.listActivityLogs(
      useAuth(ref).accessToken,
      limit: 300,
    );
  }

  Future<void> _refresh() async {
    setState(
      () => _future = auditService.listActivityLogs(
        useAuth(ref).accessToken,
        limit: 300,
      ),
    );
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['audit:read'],
      fallback: const Center(child: Text('No access to audit logs.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Activity Logs',
              subtitle: 'Recent admin activity and changes.',
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
                      child: Text('Failed to load logs: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }
                final raw = snapshot.data?['logs'];
                final rows = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];

                return AdminTableCard(
                  isEmpty: rows.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No activity logs found.'),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = rows[index];
                      return ListTile(
                        title: Text(log['action']?.toString() ?? 'action'),
                        subtitle: Text(
                          'Actor: ${log['actor_id'] ?? '—'} · Target: ${log['target_type'] ?? '—'}:${log['target_id'] ?? '—'}\n${log['created_at'] ?? ''}',
                        ),
                        isThreeLine: true,
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
