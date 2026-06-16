import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminChatSupportPage extends ConsumerStatefulWidget {
  const AdminChatSupportPage({super.key});

  @override
  ConsumerState<AdminChatSupportPage> createState() =>
      _AdminChatSupportPageState();
}

class _AdminChatSupportPageState extends ConsumerState<AdminChatSupportPage> {
  Future<Map<String, dynamic>>? _ticketsFuture;
  String? _selectedTicketId;
  Future<Map<String, dynamic>>? _messagesFuture;
  final TextEditingController _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadTickets() {
    return supportService.listTickets(useAuth(ref).accessToken);
  }

  Future<Map<String, dynamic>> _loadMessages(String ticketId) {
    return supportService.listMessages(useAuth(ref).accessToken, ticketId);
  }

  Future<void> _refreshTickets() async {
    setState(() {
      _ticketsFuture = _loadTickets();
    });
    await _ticketsFuture;
  }

  void _selectTicket(String ticketId) {
    setState(() {
      _selectedTicketId = ticketId;
      _messagesFuture = _loadMessages(ticketId);
    });
  }

  Future<void> _sendMessage() async {
    final ticketId = _selectedTicketId;
    final text = _messageCtrl.text.trim();
    if (ticketId == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await supportService.postMessage(
        useAuth(ref).accessToken,
        ticketId,
        text,
        messageKind: 'staff',
      );
      _messageCtrl.clear();
      setState(() => _messagesFuture = _loadMessages(ticketId));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['communication:chat:reply', 'support:reply'],
      fallback: const Center(child: Text('No access to support chat.')),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Chat Support',
              subtitle: 'Support tickets and conversation thread.',
              action: OutlinedButton.icon(
                onPressed: _refreshTickets,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _ticketsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load tickets: ${snapshot.error}',
                            ),
                          );
                        }
                        final raw = snapshot.data?['tickets'];
                        final tickets = raw is List
                            ? raw
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList(growable: false)
                            : <Map<String, dynamic>>[];
                        return AdminTableCard(
                          isEmpty: tickets.isEmpty,
                          empty: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No support tickets.'),
                          ),
                          child: ListView.separated(
                            itemCount: tickets.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = tickets[index];
                              final id = t['id']?.toString() ?? '';
                              final selected = _selectedTicketId == id;
                              return ListTile(
                                selected: selected,
                                onTap: () => _selectTicket(id),
                                title: Text(
                                  t['subject']?.toString() ?? 'Untitled',
                                ),
                                subtitle: Text('Status: ${t['status'] ?? '—'}'),
                                trailing: StatusBadge(
                                  label: t['priority']?.toString() ?? 'normal',
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: _selectedTicketId == null
                                ? const Center(
                                    child: Text(
                                      'Select a ticket to open chat.',
                                    ),
                                  )
                                : FutureBuilder<Map<String, dynamic>>(
                                    future: _messagesFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Failed to load messages: ${snapshot.error}',
                                          ),
                                        );
                                      }
                                      final raw = snapshot.data?['messages'];
                                      final messages = raw is List
                                          ? raw
                                                .whereType<Map>()
                                                .map(
                                                  (e) =>
                                                      Map<String, dynamic>.from(
                                                        e,
                                                      ),
                                                )
                                                .toList(growable: false)
                                          : <Map<String, dynamic>>[];
                                      if (messages.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No messages in this ticket.',
                                          ),
                                        );
                                      }
                                      return ListView.builder(
                                        reverse: true,
                                        padding: const EdgeInsets.all(12),
                                        itemCount: messages.length,
                                        itemBuilder: (context, index) {
                                          final m =
                                              messages[messages.length -
                                                  1 -
                                                  index];
                                          final kind =
                                              m['message_kind']?.toString() ??
                                              'user';
                                          final isStaff = kind == 'staff';
                                          return Align(
                                            alignment: isStaff
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              constraints: const BoxConstraints(
                                                maxWidth: 420,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isStaff
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                m['body']?.toString() ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageCtrl,
                                    minLines: 1,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText: 'Reply to ticket...',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: _sending ? null : _sendMessage,
                                  icon: _sending
                                      ? const SizedBox.square(
                                          dimension: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 16),
                                  label: const Text('Send'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
