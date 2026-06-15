import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/services/rbac_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

class RbacViewModel {
  const RbacViewModel({
    required this.roles,
    required this.permissions,
    this.assignableRoles = const <Map<String, dynamic>>[],
    this.canManageStaff = false,
  });

  factory RbacViewModel.fromAuthUser(SessionUser? user) {
    return RbacViewModel(
      roles: List<String>.from(user?.roles ?? const []),
      permissions: List<String>.from(user?.permissions ?? const []),
    );
  }

  final List<String> roles;
  final List<String> permissions;
  final List<Map<String, dynamic>> assignableRoles;
  final bool canManageStaff;

  bool hasPermission(String permission) {
    return roles.contains('super_admin') || permissions.contains(permission);
  }

  bool hasPermPrefix(String prefix) {
    if (roles.contains('super_admin')) return true;
    final normalized = prefix.endsWith(':') ? prefix : '$prefix:';
    return permissions.any((name) => name == prefix || name.startsWith(normalized));
  }
}

final rbacServiceProvider = Provider<RbacService>((ref) => RbacService());

final rbacProvider = FutureProvider<RbacViewModel>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  final user = auth.user;

  if (!auth.isReady || token == null || token.isEmpty) {
    return RbacViewModel.fromAuthUser(user);
  }

  try {
    final me = await ref.read(rbacServiceProvider).getMe(token);
    return RbacViewModel(
      roles: me.roles.isNotEmpty ? me.roles : List<String>.from(user?.roles ?? const []),
      permissions: me.permissions.isNotEmpty ? me.permissions : List<String>.from(user?.permissions ?? const []),
      assignableRoles: me.assignableRoles,
      canManageStaff: me.canManageStaff,
    );
  } catch (_) {
    return RbacViewModel.fromAuthUser(user);
  }
});
