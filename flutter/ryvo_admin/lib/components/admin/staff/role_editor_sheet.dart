import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

Future<bool?> showRoleEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> role,
  required List<Map<String, dynamic>> allPermissions,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _RoleEditorSheet(
      role: role,
      allPermissions: allPermissions,
    ),
  );
}

class _RoleEditorSheet extends ConsumerStatefulWidget {
  const _RoleEditorSheet({
    required this.role,
    required this.allPermissions,
  });

  final Map<String, dynamic> role;
  final List<Map<String, dynamic>> allPermissions;

  @override
  ConsumerState<_RoleEditorSheet> createState() => _RoleEditorSheetState();
}

class _RoleEditorSheetState extends ConsumerState<_RoleEditorSheet> {
  late final TextEditingController _descCtrl;
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.role['description']?.toString() ?? '');
    final perms = widget.role['permissions'];
    _selected = perms is List ? perms.map((e) => e.toString()).toSet() : {};
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await rbacService.updateRole(
        ref.read(authProvider).accessToken,
        widget.role['id']?.toString() ?? '',
        description: _descCtrl.text.trim(),
        permissions: _selected.toList(growable: false),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save role: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.role['name']?.toString() ?? 'Role';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit $roleName', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Permissions (${_selected.length})'),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.allPermissions.length,
                itemBuilder: (context, index) {
                  final perm = widget.allPermissions[index];
                  final name = perm['name']?.toString() ?? '';
                  final selected = _selected.contains(name);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(name);
                        } else {
                          _selected.remove(name);
                        }
                      });
                    },
                    title: Text(name),
                    subtitle: Text(perm['description']?.toString() ?? ''),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save role'),
            ),
          ],
        ),
      ),
    );
  }
}
