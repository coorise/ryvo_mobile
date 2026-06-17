import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalChatSupportPanel extends ConsumerStatefulWidget {
  const PortalChatSupportPanel({super.key});

  @override
  ConsumerState<PortalChatSupportPanel> createState() => _PortalChatSupportPanelState();
}

class _PortalChatSupportPanelState extends ConsumerState<PortalChatSupportPanel> {
  final _replyController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tickets = const [];
  List<Map<String, dynamic>> _messages = const [];
  String? _selectedTicketId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTickets());
  }

  @override
  void dispose() {
    _replyController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final auth = useAuth(ref);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await supportService.listTickets(auth.accessToken);
      final mine = portalMapList(res, 'tickets')
          .where((tk) => portalStr(tk['user_id'], '') == portalStr(auth.user?.id, ''))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _tickets = mine;
        _loading = false;
      });
      if (_selectedTicketId != null) {
        await _loadMessages(_selectedTicketId!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.support.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages(String ticketId) async {
    final auth = useAuth(ref);
    try {
      final res = await supportService.listMessages(auth.accessToken, ticketId);
      if (!mounted) return;
      setState(() => _messages = portalMapList(res, 'messages'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages = const []);
    }
  }

  Future<void> _sendReply() async {
    final ticketId = _selectedTicketId;
    if (ticketId == null) return;
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    final auth = useAuth(ref);
    await supportService.postMessage(auth.accessToken, ticketId, body);
    _replyController.clear();
    await _loadMessages(ticketId);
  }

  Future<void> _createTicket() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) return;
    final auth = useAuth(ref);
    final created = await supportService.createTicket(auth.accessToken, {
      'subject': subject,
      'category': 'complaint',
    });
    final ticket = created['ticket'];
    final ticketId = ticket is Map ? portalStr(ticket['id'], '') : '';
    if (ticketId.isNotEmpty) {
      await supportService.postMessage(auth.accessToken, ticketId, body);
      _subjectController.clear();
      _bodyController.clear();
      setState(() => _selectedTicketId = ticketId);
      await _loadTickets();
      await _loadMessages(ticketId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    final selected = _tickets.firstWhere(
      (ticket) => portalStr(ticket['id']) == _selectedTicketId,
      orElse: () => const {},
    );

    return AdminMobileColumnTabs(
      tabs: [
        T.portal('portal.support.myTickets'),
        T.portal('portal.support.thread'),
        T.portal('portal.support.newTicket'),
      ],
      tabHeight: 420,
      children: [
        _supportTabShell(
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _tickets[index];
              final id = portalStr(ticket['id']);
              final selected = id == _selectedTicketId;
              return ListTile(
                selected: selected,
                title: Text(portalStr(ticket['subject'])),
                subtitle: Text(portalStr(ticket['status'])),
                onTap: () {
                  setState(() => _selectedTicketId = id);
                  _loadMessages(id);
                },
              );
            },
          ),
        ),
        _supportTabShell(
          Padding(
            padding: const EdgeInsets.all(12),
            child: _selectedTicketId == null
                ? portalEmpty(T.portal('portal.support.selectTicket'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        portalStr(selected['subject']),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        formatLastSeen(portalStr(selected['created_at'], '')),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatLastSeen(portalStr(message['created_at'], '')),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(portalStr(message['body'])),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ShadInput(
                              controller: _replyController,
                              placeholder: Text(T.portal('portal.support.replyPlaceholder')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShadButton(onPressed: _sendReply, child: Text(T.portal('portal.support.send'))),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        _supportTabShell(
          SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ShadInput(
                  controller: _subjectController,
                  placeholder: Text(T.portal('portal.support.subjectPlaceholder')),
                ),
                const SizedBox(height: 10),
                ShadInput(
                  controller: _bodyController,
                  placeholder: Text(T.portal('portal.support.messagePlaceholder')),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton(
                    onPressed: _createTicket,
                    child: Text(T.portal('portal.support.create')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _supportTabShell(Widget child) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SizedBox.expand(child: child),
    );
  }
}
