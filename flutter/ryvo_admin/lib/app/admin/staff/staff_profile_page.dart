import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/profile_header.dart';
import 'package:ryvo_admin/components/admin/profile_manage_section.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class StaffProfilePage extends ConsumerStatefulWidget {
  const StaffProfilePage({super.key});

  @override
  ConsumerState<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends ConsumerState<StaffProfilePage> {
  Future<Map<String, dynamic>>? _future;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = GoRouterState.of(context).uri.queryParameters['id'];
    if (userId != _loadedUserId) {
      _loadedUserId = userId;
      _future = userId == null || userId.isEmpty ? null : _load(userId);
    }
  }

  Future<Map<String, dynamic>> _load(String userId) {
    return rbacService.getUserDetail(ref.read(authProvider).accessToken, userId);
  }

  void _refresh() {
    final userId = _loadedUserId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _future = _load(userId));
  }

  Map<String, String> _customFields(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = GoRouterState.of(context).uri.queryParameters['id'];
    final canEdit = ref.watch(rbacProvider).maybeWhen(
          data: (vm) => vm.hasPermission('staff:update') || vm.hasPermission('users:update'),
          orElse: () => false,
        );

    return PermissionGate(
      permissions: const ['staff:read', 'roles:read'],
      fallback: const Center(child: Text('You do not have access to view staff profile.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AdminListStack(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.adminStaffList),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to staff'),
            ),
            if (userId == null || userId.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No user id found in query params.'),
                ),
              )
            else
              FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Failed to load user detail: ${snapshot.error}'),
                      ),
                    );
                  }
                  final user = (snapshot.data?['user'] is Map)
                      ? Map<String, dynamic>.from(snapshot.data!['user'] as Map)
                      : <String, dynamic>{};
                  if (user.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('User not found.'),
                      ),
                    );
                  }

                  final rolesRaw = user['roles'];
                  final roles = rolesRaw is List
                      ? rolesRaw.map((e) => e.toString()).toList()
                      : const <String>[];

                  return AdminListStack(
                    children: [
                      ProfileHeader(
                        user: ProfileHeaderData(
                          fullName: user['full_name']?.toString(),
                          email: user['email']?.toString() ?? '—',
                          phone: user['phone']?.toString(),
                          avatarUrl: user['avatar_url']?.toString(),
                          createdAt: user['created_at']?.toString(),
                          updatedAt: user['updated_at']?.toString(),
                          emailVerified: user['email_verified'] == true,
                          roles: roles,
                        ),
                      ),
                      ProfileManageSection(
                        userId: userId,
                        canEdit: canEdit,
                        onSaved: _refresh,
                        initial: ProfileManageValues(
                          fullName: user['full_name']?.toString(),
                          email: user['email']?.toString() ?? '',
                          phone: user['phone']?.toString(),
                          username: user['username']?.toString(),
                          customFields: _customFields(user['custom_fields']),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
