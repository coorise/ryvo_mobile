import 'package:ryvo_admin/lib/base_service.dart';

class MapService extends BaseService {
  MapService() : super('routing-engine');

  Future<Map<String, dynamic>> listOnlineDrivers(String? token, {String? query}) {
    final qs = query == null || query.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(query)}';
    return get<Map<String, dynamic>>('/v1/admin/map/online-drivers$qs', token: token);
  }

  Future<Map<String, dynamic>> searchPlaces(String? token, String query) {
    final qs = '?q=${Uri.encodeQueryComponent(query)}';
    return get<Map<String, dynamic>>('/v1/admin/map/search$qs', token: token);
  }
}

final mapService = MapService();
