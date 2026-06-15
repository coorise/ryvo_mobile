import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class NewStaffPage extends ConsumerStatefulWidget {
  const NewStaffPage({super.key});

  @override
  ConsumerState<NewStaffPage> createState() => _NewStaffPageState();
}

class _NewStaffPageState extends ConsumerState<NewStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _roleId;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Map<String, dynamic>> assignableRoles) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final token = useAuth(ref).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final created = await rbacService.createUser(
        token,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );

      final createdUser = (created['user'] is Map)
          ? Map<String, dynamic>.from(created['user'] as Map)
          : <String, dynamic>{};
      final userId = createdUser['id']?.toString();
      final roleId =
          _roleId ??
          (assignableRoles.isNotEmpty
              ? assignableRoles.first['id']?.toString()
              : null);
      if (userId != null && roleId != null && roleId.isNotEmpty) {
        await rbacService.assignRole(token, userId, roleId);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Staff member created successfully.')),
      );
      if (userId != null && userId.isNotEmpty) {
        context.go('${Routes.adminStaffProfile}?id=$userId');
      } else {
        context.go(Routes.adminStaffList);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create staff: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rbac = ref.watch(rbacProvider);

    return PermissionGate(
      permissions: const ['staff:create', 'users:create'],
      fallback: const Center(
        child: Text('You do not have access to create staff.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: rbac.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Failed to load role options.'),
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
                        'Create staff',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Email is invalid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) return 'Use at least 6 characters';
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
                            _submitting ? 'Creating...' : 'Create staff',
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
