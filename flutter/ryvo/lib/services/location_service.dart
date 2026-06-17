import 'package:ryvo/lib/base_service.dart';

class LocationService extends BaseService {
  LocationService() : super('location-ingest');

  Future<Map<String, dynamic>> setOnline(
    String? token, {
    required bool isOnline,
    double? lat,
    double? lng,
  }) {
    return post<Map<String, dynamic>>(
      '/v1/online',
      {
        'is_online': isOnline,
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> ingestLocation(
    String? token, {
    required double lat,
    required double lng,
    double? accuracyM,
    double? speedKmh,
    double? heading,
    String? tripId,
  }) {
    return post<Map<String, dynamic>>(
      '/v1/ingest',
      {
        'lat': lat,
        'lng': lng,
        if (accuracyM != null) 'accuracy_m': accuracyM,
        if (speedKmh != null) 'speed_kmh': speedKmh,
        if (heading != null) 'heading': heading,
        if (tripId != null) 'trip_id': tripId,
      },
      token: token,
    );
  }
}

final locationService = LocationService();
