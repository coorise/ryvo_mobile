import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/lib/api_client.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

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
    List<Map<String, dynamic>> mapList(dynamic raw) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
    }

    return AdminDashboardData(
      stats: json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : const {},
      badges: json['badges'] is Map ? Map<String, dynamic>.from(json['badges'] as Map) : const {},
      alerts: mapList(json['alerts']),
      chart: mapList(json['chart']),
      pendingDrivers: mapList(json['pending_drivers']),
      recentAudit: mapList(json['recent_audit']),
      live: json['live'] is Map ? Map<String, dynamic>.from(json['live'] as Map) : const {},
    );
  }
}

final adminDashboardProvider = FutureProvider<AdminDashboardData?>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isReady || token == null || token.isEmpty) return null;

  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final json = await apiRequest<Map<String, dynamic>>(
    'audit-service',
    '/v1/admin/dashboard',
    options: RequestOptions(token: token),
  );
  return AdminDashboardData.fromJson(json);
});
