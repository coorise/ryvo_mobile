import 'package:ryvo_admin/lib/api_client.dart';
import 'package:ryvo_admin/lib/base_service.dart';

class RbacMe {
  const RbacMe({
    required this.roles,
    required this.permissions,
    required this.assignableRoles,
    required this.canManageStaff,
  });

  final List<String> roles;
  final List<String> permissions;
  final List<Map<String, dynamic>> assignableRoles;
  final bool canManageStaff;

  factory RbacMe.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMapList(dynamic raw) {
      if (raw is! List) {
        return const [];
      }
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final rolesRaw = json['roles'];
    final permsRaw = json['permissions'];
    return RbacMe(
      roles: rolesRaw is List ? rolesRaw.map((e) => e.toString()).toList() : const [],
      permissions: permsRaw is List ? permsRaw.map((e) => e.toString()).toList() : const [],
      assignableRoles: asMapList(json['assignable_roles']),
      canManageStaff: json['can_manage_staff'] == true,
    );
  }
}

class RbacService extends BaseService {
  RbacService() : super('auth-hooks');

  Future<RbacMe> getMe(String? token) async {
    final json = await get<Map<String, dynamic>>('/v1/admin/rbac/me', token: token);
    return RbacMe.fromJson(json);
  }

  Future<Map<String, dynamic>> getMatrix(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/roles', token: token);
  }

  Future<Map<String, dynamic>> getPermissions(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/permissions', token: token);
  }

  Future<Map<String, dynamic>> createRole(
    String? token, {
    required String name,
    String? description,
    required List<String> permissions,
  }) {
    return post<Map<String, dynamic>>('/v1/admin/roles', {
      'name': name,
      'description': description,
      'permissions': permissions,
    }, token: token);
  }

  Future<Map<String, dynamic>> updateRole(
    String? token,
    String roleId, {
    String? description,
    List<String>? permissions,
  }) {
    return patch<Map<String, dynamic>>('/v1/admin/roles/$roleId', {
      'description': description,
      'permissions': permissions,
    }, token: token);
  }

  Future<Map<String, dynamic>> deleteRole(String? token, String roleId) {
    return delete<Map<String, dynamic>>('/v1/admin/roles/$roleId', token: token);
  }

  Future<Map<String, dynamic>> listUsers(String? token, {String kind = 'clients'}) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users?kind=$kind',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> getUserDetail(String? token, String userId) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users/$userId',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> createUser(
    String? token, {
    required String email,
    required String password,
    String? fullName,
  }) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users',
      options: RequestOptions(
        method: 'POST',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
        token: token,
      ),
    );
  }

  Future<Map<String, dynamic>> updateUser(
    String? token,
    String userId,
    Map<String, dynamic> body,
  ) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users/$userId',
      options: RequestOptions(method: 'PATCH', body: body, token: token),
    );
  }

  Future<Map<String, dynamic>> assignRole(String? token, String userId, String roleId) {
    return post<Map<String, dynamic>>('/v1/admin/roles/assign', {
      'user_id': userId,
      'role_id': roleId,
    }, token: token);
  }

  Future<Map<String, dynamic>> revokeRole(String? token, String userId, String roleId) {
    return post<Map<String, dynamic>>('/v1/admin/roles/revoke', {
      'user_id': userId,
      'role_id': roleId,
    }, token: token);
  }

  Future<Map<String, dynamic>> banUser(String? token, String userId, {String? reason}) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users/ban',
      options: RequestOptions(
        method: 'POST',
        body: {'user_id': userId, 'reason': reason},
        token: token,
      ),
    );
  }

  Future<Map<String, dynamic>> unbanUser(String? token, String userId) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users/unban',
      options: RequestOptions(method: 'POST', body: {'user_id': userId}, token: token),
    );
  }

  Future<Map<String, dynamic>> deleteUser(String? token, String userId, String mode) {
    return apiRequest<Map<String, dynamic>>(
      'profile-service',
      '/v1/admin/users/$userId',
      options: RequestOptions(method: 'DELETE', body: {'mode': mode}, token: token),
    );
  }
}

final rbacService = RbacService();
