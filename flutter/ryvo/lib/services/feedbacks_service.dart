import 'package:ryvo/lib/base_service.dart';

class FeedbacksService extends BaseService {
  FeedbacksService() : super('support-service');

  Future<Map<String, dynamic>> getAnalytics(
    String? token,
    String category,
    String granularity,
  ) {
    final qs = Uri(queryParameters: {
      'category': category,
      'granularity': granularity,
    }).query;
    return get<Map<String, dynamic>>('/v1/admin/feedbacks/analytics?$qs', token: token);
  }
}

final feedbacksService = FeedbacksService();
