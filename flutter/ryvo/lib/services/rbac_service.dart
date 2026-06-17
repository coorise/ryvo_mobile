import 'package:ryvo/lib/base_service.dart';

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
      if (raw is! List) return const [];
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
}
