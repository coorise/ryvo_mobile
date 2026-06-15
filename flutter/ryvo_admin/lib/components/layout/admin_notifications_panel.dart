import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/hooks/use_admin_dashboard.dart';
import 'package:ryvo_admin/hooks/use_notifications.dart';

/// Dropdown panel for unread inbox notifications (mirrors web admin shell).
class AdminNotificationsPanel extends ConsumerWidget {
  const AdminNotificationsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final dashboardAsync = ref.watch(adminDashboardProvider);

    final notifications = notificationsAsync.valueOrNull?.notifications ?? const [];
    final ticketBadge =
        (dashboardAsync.valueOrNull?.badges['tickets'] as num?)?.toInt() ?? 0;
    final unreadInbox =
        notifications.where((n) => !n.isRead).length + ticketBadge;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 320,
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (unreadInbox > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unreadInbox',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No notifications',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.take(12).length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        final created = DateTime.tryParse(n.createdAt);
                        final label = created == null
                            ? n.createdAt
                            : DateFormat.yMMMd().add_jm().format(created.toLocal());
                        return ListTile(
                          dense: true,
                          title: Text(
                            n.type,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(label, style: const TextStyle(fontSize: 11)),
                          onTap: () async {
                            if (!n.isRead) {
                              await notificationsAsync.valueOrNull?.markRead(n.id);
                            }
                            if (context.mounted) {
                              onClose();
                              context.go(Routes.adminCommNotifications);
                            }
                          },
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            TextButton(
              onPressed: () {
                onClose();
                context.go(Routes.adminCommNotifications);
              },
              child: const Text('View all'),
            ),
          ],
        ),
      ),
    );
  }
}
