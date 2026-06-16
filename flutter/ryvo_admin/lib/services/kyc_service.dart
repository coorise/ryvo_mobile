import 'package:ryvo_admin/lib/base_service.dart';

class KycService extends BaseService {
  KycService() : super('kyc-service');

  Future<Map<String, dynamic>> getQueue(String? token) {
    return get<Map<String, dynamic>>('/v1/queue', token: token);
  }

  Future<Map<String, dynamic>> review(
    String? token,
    String driverId,
    String docType,
    String status, {
    String? rejectionReason,
  }) {
    return post<Map<String, dynamic>>('/v1/review', {
      'driver_id': driverId,
      'doc_type': docType,
      'status': status,
      'rejection_reason': rejectionReason,
    }, token: token);
  }
}

final kycService = KycService();
