import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class AssignRolePage extends ConsumerStatefulWidget {
  const AssignRolePage({super.key});

  @override
  ConsumerState<AssignRolePage> createState() => _AssignRolePageState();
}

class _AssignRolePageState extends ConsumerState<AssignRolePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String? _roleId;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Map<String, dynamic>> assignableRoles) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final usersRes = await rbacService.listUsers(token, kind: 'all');
      final users = (usersRes['users'] is List)
          ? (usersRes['users'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      final email = _emailCtrl.text.trim().toLowerCase();
      final matched = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => (u?['email']?.toString().toLowerCase() ?? '') == email,
        orElse: () => null,
      );

      if (matched == null) {
        throw Exception('User not found with this email');
      }

      final roleId =
          _roleId ??
          (assignableRoles.isNotEmpty
              ? assignableRoles.first['id']?.toString()
              : null);
      if (roleId == null || roleId.isEmpty) {
        throw Exception('No role selected');
      }

      await rbacService.assignRole(token, matched['id'].toString(), roleId);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Role assigned successfully.')),
      );
      context.go(Routes.adminStaffList);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to assign role: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rbac = ref.watch(rbacProvider);

    return PermissionGate(
      permissions: const ['staff:update'],
      fallback: const Center(
        child: Text('You do not have access to assign roles.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: rbac.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Failed to load assignable roles.'),
              data: (vm) {
                final assignableRoles = vm.assignableRoles;
                _roleId ??= assignableRoles.isNotEmpty
                    ? assignableRoles.first['id']?.toString()
                    : null;
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign role',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'User email',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Email is invalid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _roleId,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: assignableRoles
                            .map((role) {
                              final id = role['id']?.toString() ?? '';
                              final name = role['name']?.toString() ?? id;
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(name),
                              );
                            })
                            .toList(growable: false),
                        onChanged: (value) => setState(() => _roleId = value),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : () => _submit(assignableRoles),
                          child: Text(
                            _submitting ? 'Assigning...' : 'Assign role',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
