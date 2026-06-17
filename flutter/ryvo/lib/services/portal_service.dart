import 'package:ryvo/lib/base_service.dart';

class PortalService extends BaseService {
  PortalService() : super('trip-lifecycle');

  Future<Map<String, dynamic>> getActiveTrip(String? token) {
    return get<Map<String, dynamic>>('/v1/trip/active', token: token);
  }

  Future<Map<String, dynamic>> listMyTrips(String? token, {int limit = 100}) {
    return get<Map<String, dynamic>>('/v1/me/trips?limit=$limit', token: token);
  }

  Future<Map<String, dynamic>> listMyPayments(
    String? token, {
    String? status,
    int limit = 500,
  }) {
    final params = <String, String>{'limit': '$limit'};
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    final q = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return get<Map<String, dynamic>>('/v1/me/payments?$q', token: token);
  }
}

final portalService = PortalService();
