import 'package:ryvo/lib/base_service.dart';

class NotificationService extends BaseService {
  NotificationService() : super('notification-service');

  Future<Map<String, dynamic>> getInbox(String? token) {
    return get<Map<String, dynamic>>('/v1/inbox', token: token);
  }

  Future<Map<String, dynamic>> markRead(String? token, String id) {
    return patch<Map<String, dynamic>>('/v1/inbox/$id/read', {}, token: token);
  }

  Future<Map<String, dynamic>> remove(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/inbox/$id', token: token);
  }
}

final notificationService = NotificationService();
