import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() {
    final token = useAuth(ref).accessToken;
    return notificationService.getInbox(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markRead(String id) async {
    final token = useAuth(ref).accessToken;
    await notificationService.markRead(token, id);
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _remove(String id) async {
    final token = useAuth(ref).accessToken;
    await notificationService.remove(token, id);
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
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

                return AdminTableCard(
                  isEmpty: notifications.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Inbox is empty.'),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
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

                      return ListTile(
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
                        leading: StatusBadge(
                          label: isRead ? 'Read' : 'Unread',
                          variant: isRead
                              ? StatusBadgeVariant.defaultVariant
                              : StatusBadgeVariant.info,
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (!isRead)
                              IconButton(
                                tooltip: 'Mark read',
                                onPressed: () =>
                                    _markRead(n['id']?.toString() ?? ''),
                                icon: const Icon(Icons.done_all),
                              ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _remove(n['id']?.toString() ?? ''),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemCount: notifications.length,
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
