import 'package:ryvo_admin/lib/base_service.dart';

class DriversService extends BaseService {
  DriversService() : super('kyc-service');

  Future<Map<String, dynamic>> listDrivers(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/drivers', token: token);
  }

  Future<Map<String, dynamic>> getDriver(String? token, String driverId) {
    return get<Map<String, dynamic>>('/v1/admin/drivers/$driverId', token: token);
  }

  Future<Map<String, dynamic>> createDriver(
    String? token, {
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) {
    return post<Map<String, dynamic>>('/v1/admin/drivers', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
    }, token: token);
  }

  Future<Map<String, dynamic>> getDocumentViewUrl(
    String? token,
    String driverId,
    String docType,
  ) {
    return get<Map<String, dynamic>>(
      '/v1/admin/drivers/$driverId/documents/$docType/view-url',
      token: token,
    );
  }

  Future<Map<String, dynamic>> reviewDocument(
    String? token,
    String driverId,
    String docType,
    String status, {
    String? rejectionReason,
  }) {
    return post<Map<String, dynamic>>(
      '/v1/admin/drivers/$driverId/documents/$docType/review',
      {'status': status, 'rejection_reason': rejectionReason},
      token: token,
    );
  }
}

final driversService = DriversService();
