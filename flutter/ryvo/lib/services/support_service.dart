import 'package:ryvo/lib/base_service.dart';

class SupportService extends BaseService {
  SupportService() : super('support-service');

  Future<Map<String, dynamic>> listTickets(String? token) {
    return get<Map<String, dynamic>>('/v1/tickets', token: token);
  }

  Future<Map<String, dynamic>> createTicket(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/tickets', body, token: token);
  }

  Future<Map<String, dynamic>> patchTicket(
    String? token,
    String ticketId,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/tickets/$ticketId', body, token: token);
  }

  Future<Map<String, dynamic>> listMessages(String? token, String ticketId) {
    return get<Map<String, dynamic>>('/v1/tickets/$ticketId/messages', token: token);
  }

  Future<Map<String, dynamic>> postMessage(
    String? token,
    String ticketId,
    String body, {
    String? messageKind,
  }) {
    return post<Map<String, dynamic>>('/v1/tickets/$ticketId/messages', {
      'body': body,
      'message_kind': messageKind,
    }, token: token);
  }

  Future<Map<String, dynamic>> createAdminTicket(
    String? token,
    Map<String, dynamic> body,
  ) {
    return post<Map<String, dynamic>>('/v1/admin/tickets', body, token: token);
  }
}

final supportService = SupportService();
