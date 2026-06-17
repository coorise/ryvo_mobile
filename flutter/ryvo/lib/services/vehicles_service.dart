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

  Future<Map<String, dynamic>> setActiveVehicle(String? token, String vehicleId) {
    return post<Map<String, dynamic>>('/v1/vehicles/$vehicleId/set-active', {}, token: token);
  }
}

final vehiclesService = VehiclesService();
