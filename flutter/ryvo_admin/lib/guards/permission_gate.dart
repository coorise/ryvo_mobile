import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

/// Mirrors web `PermissionGate` — optional roles/permissions (any match).
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.child,
    this.roles,
    this.permissions,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final List<String>? roles;
  final List<String>? permissions;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return fallback;

    if (roles != null && roles!.isNotEmpty && !Abac.hasRole(user, roles!)) {
      return fallback;
    }

    if (permissions == null || permissions!.isEmpty) return child;

    final rbac = ref.watch(rbacProvider);
    bool allowed(RbacViewModel vm) =>
        permissions!.any((p) => vm.hasPermission(p) || Abac.hasPermission(user, p));

    return rbac.when(
      data: (vm) => allowed(vm) ? child : fallback,
      loading: () =>
          permissions!.any((p) => Abac.hasPermission(user, p)) ? child : fallback,
      error: (_, __) =>
          permissions!.any((p) => Abac.hasPermission(user, p)) ? child : fallback,
    );
  }
}
