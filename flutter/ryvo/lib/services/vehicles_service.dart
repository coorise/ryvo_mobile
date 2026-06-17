import 'package:ryvo/lib/base_service.dart';

class VehiclesService extends BaseService {
  VehiclesService() : super('kyc-service');

  Future<Map<String, dynamic>> listMine(String? token) {
    return get<Map<String, dynamic>>('/v1/vehicles', token: token);
  }

  Future<Map<String, dynamic>> getVehicle(String? token, String vehicleId) {
    return get<Map<String, dynamic>>('/v1/vehicles/$vehicleId', token: token);
  }

  Future<Map<String, dynamic>> create(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/vehicles', body, token: token);
  }

  Future<Map<String, dynamic>> update(String? token, String vehicleId, Map<String, dynamic> body) {
    return patch<Map<String, dynamic>>('/v1/vehicles/$vehicleId', body, token: token);
  }

  Future<Map<String, dynamic>> remove(String? token, String vehicleId) {
    return delete<Map<String, dynamic>>('/v1/vehicles/$vehicleId', token: token);
  }

  Future<Map<String, dynamic>> submitDocument(
    String? token,
    String vehicleId, {
    required String docType,
    required String s3Key,
    String? label,
  }) {
    return post<Map<String, dynamic>>('/v1/vehicles/$vehicleId/documents', {
      'doc_type': docType,
      's3_key': s3Key,
      if (label != null && label.isNotEmpty) 'label': label,
    }, token: token);
  }

  Future<Map<String, dynamic>> getDocumentViewUrl(String? token, String vehicleId, String docId) {
    return get<Map<String, dynamic>>('/v1/vehicles/$vehicleId/documents/$docId/view-url', token: token);
  }

  Future<Map<String, dynamic>> getMediaViewUrl(String? token, String vehicleId, String key) {
    return get<Map<String, dynamic>>(
      '/v1/vehicles/$vehicleId/media/view-url?key=${Uri.encodeComponent(key)}',
      token: token,
    );
  }

  Future<Map<String, dynamic>> setActiveVehicle(String? token, String? vehicleId) {
    return patch<Map<String, dynamic>>('/v1/me/active-vehicle', {
      'vehicle_id': vehicleId,
    }, token: token);
  }
}

final vehiclesService = VehiclesService();
