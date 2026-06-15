import 'package:ryvo_admin/lib/api_client.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.stats,
    required this.badges,
    required this.alerts,
    required this.chart,
    required this.pendingDrivers,
    required this.recentAudit,
    required this.live,
  });

  final Map<String, dynamic> stats;
  final Map<String, dynamic> badges;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> chart;
  final List<Map<String, dynamic>> pendingDrivers;
  final List<Map<String, dynamic>> recentAudit;
  final Map<String, dynamic> live;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMapList(dynamic raw) {
      if (raw is! List) {
        return const [];
      }
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return AdminDashboardData(
      stats: json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : const {},
      badges: json['badges'] is Map ? Map<String, dynamic>.from(json['badges'] as Map) : const {},
      alerts: asMapList(json['alerts']),
      chart: asMapList(json['chart']),
      pendingDrivers: asMapList(json['pending_drivers']),
      recentAudit: asMapList(json['recent_audit']),
      live: json['live'] is Map ? Map<String, dynamic>.from(json['live'] as Map) : const {},
    );
  }
}

class AdminService {
  Future<AdminDashboardData> getDashboard(String? token) async {
    final json = await apiRequest<Map<String, dynamic>>(
      'audit-service',
      '/v1/admin/dashboard',
      options: RequestOptions(token: token),
    );
    return AdminDashboardData.fromJson(json);
  }

  Future<Map<String, dynamic>> getAnalytics(
    String? token,
    String period,
    String audience,
  ) {
    final qs = Uri(queryParameters: {
      'period': period,
      'audience': audience,
    }).query;
    return apiRequest<Map<String, dynamic>>(
      'audit-service',
      '/v1/admin/analytics?$qs',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> listTrips(String? token, {int limit = 100}) {
    return apiRequest<Map<String, dynamic>>(
      'trip-lifecycle',
      '/v1/admin/trips?limit=$limit',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> listPayments(
    String? token, {
    String? status,
    int? limit,
  }) {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (limit != null) {
      params['limit'] = '$limit';
    }
    final q = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return apiRequest<Map<String, dynamic>>(
      'payment-gateway',
      '/v1/admin/payments$q',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> getSettings(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/settings',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> updateSettings(
    String? token,
    Map<String, dynamic> preferences,
  ) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/settings',
      options: RequestOptions(method: 'PATCH', body: preferences, token: token),
    );
  }
}

final adminService = AdminService();
