import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class NewRolePage extends ConsumerStatefulWidget {
  const NewRolePage({super.key});

  @override
  ConsumerState<NewRolePage> createState() => _NewRolePageState();
}

class _NewRolePageState extends ConsumerState<NewRolePage> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final Set<String> _selected = <String>{};
  bool _submitting = false;
  late Future<List<String>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _loadPermissions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<List<String>> _loadPermissions() async {
    final token = useAuth(ref).accessToken;
    final matrix = await rbacService.getMatrix(token);
    final permissions = (matrix['permissions'] is List)
        ? (matrix['permissions'] as List)
              .map((e) => (e as Map)['name']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final current = ref.read(rbacProvider).valueOrNull;
    if (current == null || current.roles.contains('super_admin')) {
      return permissions;
    }
    return permissions
        .where(current.permissions.contains)
        .toList(growable: false);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role name is required.')));
      return;
    }
    setState(() => _submitting = true);
    final token = useAuth(ref).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await rbacService.createRole(
        token,
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        permissions: _selected.toList(growable: false),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Role created successfully.')),
      );
      context.go('${Routes.adminStaffList}?tab=roles');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create role: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['roles:create'],
      fallback: const Center(
        child: Text('You do not have access to create roles.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create role',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Role name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Permissions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: _permissionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Failed to load permission matrix: ${snapshot.error}',
                      );
                    }
                    final permissions = snapshot.data ?? const <String>[];
                    if (permissions.isEmpty) {
                      return const Text('No permissions available.');
                    }
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: permissions.length,
                        itemBuilder: (context, index) {
                          final perm = permissions[index];
                          final checked = _selected.contains(perm);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            title: Text(perm),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(perm);
                                } else {
                                  _selected.remove(perm);
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Creating...' : 'Create role'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
