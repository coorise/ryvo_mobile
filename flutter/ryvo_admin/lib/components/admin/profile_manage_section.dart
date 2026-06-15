import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class ProfileManageValues {
  const ProfileManageValues({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.username,
    required this.customFields,
  });

  final String? fullName;
  final String email;
  final String? phone;
  final String? username;
  final Map<String, String> customFields;
}

class _CustomRow {
  _CustomRow({required this.id, required this.key, required this.value});

  final String id;
  String key;
  String value;
}

class ProfileManageSection extends ConsumerStatefulWidget {
  const ProfileManageSection({
    super.key,
    required this.userId,
    required this.initial,
    this.canEdit,
    this.onSaved,
  });

  final String userId;
  final ProfileManageValues initial;
  final bool? canEdit;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ProfileManageSection> createState() =>
      _ProfileManageSectionState();
}

class _ProfileManageSectionState extends ConsumerState<ProfileManageSection> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _usernameCtrl;
  late List<_CustomRow> _customRows;
  bool _submitting = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.initial.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.initial.email);
    _phoneCtrl = TextEditingController(text: widget.initial.phone ?? '');
    _usernameCtrl = TextEditingController(text: widget.initial.username ?? '');
    _customRows = _rowsFromFields(widget.initial.customFields);
  }

  @override
  void didUpdateWidget(covariant ProfileManageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fullNameCtrl.text = widget.initial.fullName ?? '';
    _emailCtrl.text = widget.initial.email;
    _phoneCtrl.text = widget.initial.phone ?? '';
    _usernameCtrl.text = widget.initial.username ?? '';
    setState(() {
      _customRows = _rowsFromFields(widget.initial.customFields);
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  List<_CustomRow> _rowsFromFields(Map<String, String> fields) {
    if (fields.isEmpty) {
      return [_CustomRow(id: '0', key: '', value: '')];
    }
    return fields.entries
        .toList()
        .asMap()
        .entries
        .map(
          (e) => _CustomRow(
            id: e.key.toString(),
            key: e.value.key,
            value: e.value.value,
          ),
        )
        .toList(growable: true);
  }

  Map<String, String> _fieldsFromRows() {
    final out = <String, String>{};
    for (final row in _customRows) {
      final k = row.key.trim();
      if (k.isEmpty) continue;
      out[k] = row.value;
    }
    return out;
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    final token = useAuth(ref).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await rbacService.updateUser(token, widget.userId, {
        'full_name': _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        'username': _usernameCtrl.text.trim().isEmpty
            ? null
            : _usernameCtrl.text.trim(),
        'custom_fields': _fieldsFromRows(),
      });
      if (!mounted) return;
      setState(() => _saved = true);
      widget.onSaved?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rbac = ref.watch(rbacProvider);
    final canEdit =
        widget.canEdit ??
        rbac.maybeWhen(
          data: (vm) => vm.hasPermission('users:update'),
          orElse: () => false,
        ) ??
        false;

    if (!canEdit) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Manage profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_saved) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Saved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Update account details and custom fields.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: '@username',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Custom fields',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _customRows.add(
                        _CustomRow(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          key: '',
                          value: '',
                        ),
                      );
                    });
                  },
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add field'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._customRows.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: row.key,
                        decoration: const InputDecoration(
                          labelText: 'Key',
                          isDense: true,
                        ),
                        onChanged: (v) => row.key = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: row.value,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          isDense: true,
                        ),
                        onChanged: (v) => row.value = v,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _customRows.removeWhere((r) => r.id == row.id);
                          if (_customRows.isEmpty) {
                            _customRows.add(
                              _CustomRow(id: '0', key: '', value: ''),
                            );
                          }
                        });
                      },
                      icon: const Icon(LucideIcons.trash2, size: 18),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _save,
              child: Text(_submitting ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
