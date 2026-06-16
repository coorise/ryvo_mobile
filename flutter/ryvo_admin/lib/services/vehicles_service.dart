import 'package:ryvo_admin/lib/base_service.dart';

class VehiclesService extends BaseService {
  VehiclesService() : super('kyc-service');

  Future<Map<String, dynamic>> reviewVehicle(
    String? token,
    String vehicleId,
    String status, {
    String? rejectionReason,
  }) {
    return post<Map<String, dynamic>>('/v1/admin/vehicles/$vehicleId/review', {
      'status': status,
      'rejection_reason': rejectionReason,
    }, token: token);
  }

  Future<Map<String, dynamic>> reviewVehicleDocument(
    String? token,
    String vehicleId,
    String docId,
    String status, {
    String? rejectionReason,
  }) {
    return post<Map<String, dynamic>>(
      '/v1/admin/vehicles/$vehicleId/documents/$docId/review',
      {'status': status, 'rejection_reason': rejectionReason},
      token: token,
    );
  }

  Future<Map<String, dynamic>> adminGetDocumentViewUrl(
    String? token,
    String vehicleId,
    String docId,
  ) {
    return get<Map<String, dynamic>>(
      '/v1/admin/vehicles/$vehicleId/documents/$docId/view-url',
      token: token,
    );
  }

  Future<Map<String, dynamic>> adminGetMediaViewUrl(
    String? token,
    String vehicleId,
    String key,
  ) {
    final encoded = Uri.encodeQueryComponent(key);
    return get<Map<String, dynamic>>(
      '/v1/admin/vehicles/$vehicleId/media/view-url?key=$encoded',
      token: token,
    );
  }
}

const vehicleDocLabelKeys = <String, String>{
  'registration': 'drivers.vehicleDocRegistration',
  'insurance': 'drivers.vehicleDocInsurance',
  'other': 'drivers.vehicleDocOther',
};

final vehiclesService = VehiclesService();
