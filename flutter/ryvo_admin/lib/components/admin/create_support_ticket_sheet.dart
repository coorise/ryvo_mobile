import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/lib/support_utils.dart';
import 'package:ryvo_admin/services/index.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

Future<void> showCreateSupportTicketSheet(
  BuildContext context,
  WidgetRef ref, {
  required SupportAudience audience,
  required ValueChanged<String> onCreated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CreateSupportTicketSheet(
      audience: audience,
      onCreated: onCreated,
    ),
  );
}

class _CreateSupportTicketSheet extends ConsumerStatefulWidget {
  const _CreateSupportTicketSheet({
    required this.audience,
    required this.onCreated,
  });

  final SupportAudience audience;
  final ValueChanged<String> onCreated;

  @override
  ConsumerState<_CreateSupportTicketSheet> createState() =>
      _CreateSupportTicketSheetState();
}

class _CreateSupportTicketSheetState
    extends ConsumerState<_CreateSupportTicketSheet> {
  final TextEditingController _userSearchCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _usersFuture;
  String? _selectedUserId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadUsers() {
    final kind = widget.audience == SupportAudience.drivers ? 'drivers' : 'clients';
    return rbacService.listUsers(ref.read(authProvider).accessToken, kind: kind);
  }

  List<Map<String, dynamic>> _filteredUsers(Map<String, dynamic>? data) {
    final raw = data?['users'];
    if (raw is! List) return const [];
    final all = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((u) => u['banned_at'] == null && u['deleted_at'] == null)
        .toList(growable: false);
    final q = _userSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((u) {
          return u['email']?.toString().toLowerCase().contains(q) == true ||
              u['full_name']?.toString().toLowerCase().contains(q) == true ||
              u['phone']?.toString().contains(q) == true ||
              u['id']?.toString().toLowerCase().contains(q) == true;
        })
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final userId = _selectedUserId;
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (userId == null || subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a user, subject, and message.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await supportService.createAdminTicket(
        ref.read(authProvider).accessToken,
        {
          'user_id': userId,
          'subject': subject,
          'message': message,
          'audience': widget.audience == SupportAudience.drivers
              ? 'drivers'
              : 'clients',
        },
      );
      final ticket = res['ticket'];
      final ticketId = ticket is Map ? ticket['id']?.toString() : null;
      if (!mounted) return;
      Navigator.pop(context);
      if (ticketId != null) widget.onCreated(ticketId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.audience == SupportAudience.drivers
                  ? 'New driver ticket'
                  : 'New client ticket',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userSearchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search user',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = _filteredUsers(snapshot.data);
                  if (users.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final id = user['id']?.toString() ?? '';
                      final selected = _selectedUserId == id;
                      return ListTile(
                        selected: selected,
                        dense: true,
                        title: Text(
                          user['full_name']?.toString() ??
                              user['email']?.toString() ??
                              id,
                        ),
                        subtitle: Text(user['email']?.toString() ?? id),
                        onTap: () => setState(() => _selectedUserId = id),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Opening message',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
