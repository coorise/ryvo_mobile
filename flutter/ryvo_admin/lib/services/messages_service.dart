import 'package:ryvo_admin/lib/base_service.dart';

class MessagesService extends BaseService {
  MessagesService() : super('notification-service');

  Future<Map<String, dynamic>> list(String? token, {String? audience}) {
    final qs =
        audience == null || audience.isEmpty ? '' : '?audience=${Uri.encodeQueryComponent(audience)}';
    return get<Map<String, dynamic>>('/v1/admin/communication/messages$qs', token: token);
  }

  Future<Map<String, dynamic>> getById(String? token, String id) {
    return get<Map<String, dynamic>>('/v1/admin/communication/messages/$id', token: token);
  }

  Future<Map<String, dynamic>> create(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/communication/messages', body, token: token);
  }

  Future<Map<String, dynamic>> update(String? token, String id, Map<String, dynamic> body) {
    return patch<Map<String, dynamic>>('/v1/admin/communication/messages/$id', body, token: token);
  }

  Future<Map<String, dynamic>> send(String? token, String id, {Map<String, dynamic>? body}) {
    return post<Map<String, dynamic>>(
      '/v1/admin/communication/messages/$id/send',
      body ?? const {},
      token: token,
    );
  }

  Future<Map<String, dynamic>> resend(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/admin/communication/messages/$id/resend', {}, token: token);
  }

  Future<Map<String, dynamic>> remove(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/communication/messages/$id', token: token);
  }
}

final messagesService = MessagesService();
