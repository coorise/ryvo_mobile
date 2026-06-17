import 'package:ryvo/lib/base_service.dart';

class TripService extends BaseService {
  TripService() : super('trip-lifecycle');

  Future<Map<String, dynamic>> getActiveTrip(String? token) {
    return get<Map<String, dynamic>>('/v1/trip/active', token: token);
  }

  Future<Map<String, dynamic>> estimate(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/trip/estimate', body, token: token);
  }

  Future<Map<String, dynamic>> requestRide(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/trip/request', body, token: token);
  }

  Future<Map<String, dynamic>> acceptAssignment(String? token, String assignmentId) {
    return post<Map<String, dynamic>>('/v1/trip/assignments/$assignmentId/accept', {}, token: token);
  }

  Future<Map<String, dynamic>> rejectAssignment(String? token, String assignmentId) {
    return post<Map<String, dynamic>>('/v1/trip/assignments/$assignmentId/reject', {}, token: token);
  }

  Future<Map<String, dynamic>> transitionTrip(String? token, String tripId, String status) {
    return post<Map<String, dynamic>>('/v1/trip/$tripId/transition', {'status': status}, token: token);
  }
}

final tripService = TripService();
