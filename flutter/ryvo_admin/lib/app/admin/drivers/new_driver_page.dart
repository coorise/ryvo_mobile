import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/drivers_service.dart';

class NewDriverPage extends ConsumerStatefulWidget {
  const NewDriverPage({super.key});

  @override
  ConsumerState<NewDriverPage> createState() => _NewDriverPageState();
}

class _NewDriverPageState extends ConsumerState<NewDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final created = await driversService.createDriver(
        token,
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      final createdDriver = (created['driver'] is Map)
          ? Map<String, dynamic>.from(created['driver'] as Map)
          : <String, dynamic>{};
      final driverId = createdDriver['id']?.toString();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Driver created successfully.')),
      );
      if (driverId != null && driverId.isNotEmpty) {
        context.go('${Routes.adminDriversProfile}?id=$driverId');
      } else {
        context.go(Routes.adminDriversList);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create driver: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['drivers:create'],
      fallback: const Center(
        child: Text('You do not have access to create drivers.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AdminListStack(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.adminDriversList),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to drivers'),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create driver',
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
                          keyboardType: TextInputType.emailAddress,
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
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
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
                            if (v.length < 6) {
                              return 'Use at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: Text(
                              _submitting ? 'Creating...' : 'Create driver',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
