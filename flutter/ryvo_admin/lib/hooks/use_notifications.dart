import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/lib/api_client.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.userId,
    required this.channel,
    required this.type,
    required this.payload,
    required this.readAt,
    required this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String channel;
  final String type;
  final Map<String, dynamic> payload;
  final String? readAt;
  final String? sentAt;
  final String createdAt;

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : const {},
      readAt: json['read_at']?.toString(),
      sentAt: json['sent_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  bool get isRead => readAt != null && readAt!.isNotEmpty;
}

class NotificationsViewModel {
  const NotificationsViewModel({
    required this.notifications,
    required this.markRead,
  });

  final List<InboxNotification> notifications;
  final Future<void> Function(String id) markRead;

  int get unread => notifications.where((n) => !n.isRead).length;
}

final notificationsProvider = FutureProvider<NotificationsViewModel?>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return null;

  final timer = Timer.periodic(const Duration(seconds: 45), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  Future<void> markRead(String id) async {
    await apiRequest<Map<String, dynamic>>(
      'notification-service',
      '/v1/inbox/$id/read',
      options: RequestOptions(method: 'PATCH', token: token, body: const <String, dynamic>{}),
    );
    ref.invalidateSelf();
  }

  final json = await apiRequest<Map<String, dynamic>>(
    'notification-service',
    '/v1/inbox',
    options: RequestOptions(token: token),
  );
  final rows = json['notifications'] is List ? json['notifications'] as List : const [];
  final notifications = rows.whereType<Map>().map((e) => InboxNotification.fromJson(Map<String, dynamic>.from(e))).toList(growable: false);

  return NotificationsViewModel(notifications: notifications, markRead: markRead);
});
