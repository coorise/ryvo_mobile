import 'package:ryvo/lib/base_service.dart';

class TripChatService extends BaseService {
  TripChatService() : super('trip-chat');

  Future<Map<String, dynamic>> listMessages(String? token, String tripId) {
    return get<Map<String, dynamic>>('/v1/trip/$tripId/messages', token: token);
  }

  Future<Map<String, dynamic>> sendMessage(String? token, String tripId, String body) {
    return post<Map<String, dynamic>>('/v1/trip/$tripId/messages', {'body': body}, token: token);
  }
}

final tripChatService = TripChatService();
