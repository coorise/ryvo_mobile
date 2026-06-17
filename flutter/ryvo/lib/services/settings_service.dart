import 'package:ryvo/lib/api_client.dart';

class SettingsService {
  Future<Map<String, dynamic>> getMyProfile(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/me/profile',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updateMyProfile(String? token, Map<String, dynamic> body) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/me/profile',
      options: RequestOptions(method: 'PATCH', body: body, token: token),
    );
  }

  Future<Map<String, dynamic>> getGeneral(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/settings',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updateGeneral(String? token, Map<String, dynamic> preferences) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/settings',
      options: RequestOptions(method: 'PATCH', body: preferences, token: token),
    );
  }

  Future<Map<String, dynamic>> getPayment(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'payment-gateway',
      '/v1/admin/settings/payment',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updatePayment(String? token, Map<String, dynamic> config) {
    return apiRequest<Map<String, dynamic>>(
      'payment-gateway',
      '/v1/admin/settings/payment',
      options: RequestOptions(method: 'PATCH', body: config, token: token),
    );
  }

  Future<Map<String, dynamic>> listEmailTemplates(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'notification-service',
      '/v1/admin/email-templates',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updateEmailTemplate(
    String? token,
    String templateKey,
    Map<String, dynamic> body,
  ) {
    return apiRequest<Map<String, dynamic>>(
      'notification-service',
      '/v1/admin/email-templates/$templateKey',
      options: RequestOptions(method: 'PUT', body: body, token: token),
    );
  }

  Future<Map<String, dynamic>> getNotifications(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'notification-service',
      '/v1/admin/settings/notifications',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updateNotifications(
    String? token,
    List<Map<String, dynamic>> events,
  ) {
    return apiRequest<Map<String, dynamic>>(
      'notification-service',
      '/v1/admin/settings/notifications',
      options: RequestOptions(
        method: 'PATCH',
        body: {'events': events},
        token: token,
      ),
    );
  }
}

final settingsService = SettingsService();
