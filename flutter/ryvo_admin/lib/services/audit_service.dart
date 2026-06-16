import 'package:ryvo_admin/lib/base_service.dart';

class AuditService extends BaseService {
  AuditService() : super('audit-service');

  Future<Map<String, dynamic>> listActivityLogs(String? token, {int limit = 300}) {
    return get<Map<String, dynamic>>('/v1/logs?limit=$limit', token: token);
  }

  Future<Map<String, dynamic>> listLogs(String? token, {int limit = 200}) {
    return listActivityLogs(token, limit: limit);
  }

  Future<Map<String, dynamic>> listSecurityAuthEvents(String? token, {String? severity}) {
    final q = severity == null || severity.isEmpty
        ? ''
        : '?severity=${Uri.encodeQueryComponent(severity)}';
    return get<Map<String, dynamic>>('/v1/security/auth-events$q', token: token);
  }

  Future<Map<String, dynamic>> listDevices(String? token, {bool includeRevoked = true}) {
    final q = includeRevoked ? '' : '?include_revoked=false';
    return get<Map<String, dynamic>>('/v1/security/devices$q', token: token);
  }

  Future<Map<String, dynamic>> revokeDevice(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/security/devices/$id/revoke', {}, token: token);
  }
}

final auditService = AuditService();
