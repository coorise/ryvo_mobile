import 'package:ryvo_admin/lib/base_service.dart';

class RoutingService extends BaseService {
  RoutingService() : super('routing-engine');

  Future<Map<String, dynamic>> autocompletePlaces(
    String? token,
    String query, {
    double? lat,
    double? lng,
  }) {
    final params = <String, String>{'q': query};
    if (lat != null && lng != null) {
      params['lat'] = '$lat';
      params['lng'] = '$lng';
    }
    final qs = Uri(queryParameters: params).query;
    return get<Map<String, dynamic>>('/v1/places/autocomplete?$qs', token: token);
  }

  Future<Map<String, dynamic>> getPlaceDetails(String? token, String placeId) {
    final qs = Uri(queryParameters: {'place_id': placeId}).query;
    return get<Map<String, dynamic>>('/v1/places/details?$qs', token: token);
  }
}

final routingService = RoutingService();
