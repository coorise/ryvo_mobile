import 'package:google_maps_flutter/google_maps_flutter.dart';

const defaultMapCenter = LatLng(45.5017, -73.5673);

double? parseCoord(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

LatLng? driverPosition(Map<String, dynamic> driver) {
  final lat = parseCoord(driver['lat']);
  final lng = parseCoord(driver['lng']);
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  return LatLng(lat, lng);
}

String driverId(Map<String, dynamic> driver) {
  return driver['driver_id']?.toString() ?? driver['id']?.toString() ?? '';
}

String driverName(Map<String, dynamic> driver) {
  return driver['name']?.toString() ?? driverId(driver);
}

bool driverOnTrip(Map<String, dynamic> driver) {
  return driver['status']?.toString() == 'on_trip';
}

LatLng resolveMapCenter(Map<String, dynamic>? publicSettings) {
  final center = publicSettings?['defaultMapCenter'];
  if (center is! Map) return defaultMapCenter;
  final lat = parseCoord(center['lat']);
  final lng = parseCoord(center['lng']);
  if (lat == null || lng == null) return defaultMapCenter;
  return LatLng(lat, lng);
}
