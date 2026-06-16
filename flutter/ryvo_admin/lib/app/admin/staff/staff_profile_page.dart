import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class StaffProfilePage extends ConsumerWidget {
  const StaffProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = GoRouterState.of(context).uri.queryParameters['id'];
    final token = useAuth(ref).accessToken;

    return PermissionGate(
      permissions: const ['staff:read', 'roles:read'],
      fallback: const Center(
        child: Text('You do not have access to view staff profile.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AdminListStack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.go(Routes.adminStaffList),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to staff'),
              ),
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
                future: rbacService.getUserDetail(token, userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load user detail: ${snapshot.error}',
                        ),
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

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (user['full_name'] ??
                                    user['username'] ??
                                    'Staff profile')
                                .toString(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          _ReadOnlyField(
                            label: 'Email',
                            value: user['email']?.toString(),
                          ),
                          _ReadOnlyField(
                            label: 'Phone',
                            value: user['phone']?.toString(),
                          ),
                          _ReadOnlyField(
                            label: 'Username',
                            value: user['username']?.toString(),
                          ),
                          _ReadOnlyField(
                            label: 'Created',
                            value: user['created_at']?.toString(),
                          ),
                          _ReadOnlyField(
                            label: 'Updated',
                            value: user['updated_at']?.toString(),
                          ),
                          _ReadOnlyField(
                            label: 'Roles',
                            value: (user['roles'] is List)
                                ? (user['roles'] as List).join(', ')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text((value == null || value!.isEmpty) ? '—' : value!),
          ),
        ],
      ),
    );
  }
}
