import 'package:ryvo/lib/base_service.dart';

class AuditService extends BaseService {
  AuditService() : super('audit-service');

  Future<Map<String, dynamic>> listMyActivityLogs(String? token, {int limit = 200}) {
    return get<Map<String, dynamic>>('/v1/me/activity?limit=$limit', token: token);
  }

  Future<Map<String, dynamic>> listMySecurityAuthEvents(String? token, {String? severity}) {
    final q = severity == null || severity.isEmpty
        ? ''
        : '?severity=${Uri.encodeQueryComponent(severity)}';
    return get<Map<String, dynamic>>('/v1/me/security/auth-events$q', token: token);
  }

  Future<Map<String, dynamic>> listMyDevices(String? token, {bool includeRevoked = true}) {
    final q = includeRevoked ? '' : '?include_revoked=false';
    return get<Map<String, dynamic>>('/v1/me/security/devices$q', token: token);
  }

  Future<Map<String, dynamic>> revokeMyDevice(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/me/security/devices/$id/revoke', {}, token: token);
  }
}

final auditService = AuditService();
