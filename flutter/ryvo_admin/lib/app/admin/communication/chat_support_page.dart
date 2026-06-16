import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/components/admin/create_support_ticket_sheet.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/lib/support_utils.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
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
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  String _statusFilter = 'all';
  String _levelFilter = 'all';
  bool _sending = false;
  bool _patching = false;

  void _refreshSelection() => setState(() {});

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
    return supportService.listTickets(ref.read(authProvider).accessToken);
  }

  Future<Map<String, dynamic>> _loadMessages(String ticketId) {
    return supportService.listMessages(
      ref.read(authProvider).accessToken,
      ticketId,
    );
  }

  Future<void> _refreshTickets() async {
    setState(() => _ticketsFuture = _loadTickets());
    await _ticketsFuture;
  }

  void _selectTicket(String ticketId) {
    setState(() {
      _selectedTicketId = ticketId;
      _messagesFuture = _loadMessages(ticketId);
    });
  }

  void _clearTicket() {
    setState(() {
      _selectedTicketId = null;
      _messagesFuture = null;
    });
  }

  Map<String, dynamic>? _selectedTicket(List<Map<String, dynamic>> tickets) {
    final id = _selectedTicketId;
    if (id == null) return null;
    for (final ticket in tickets) {
      if (ticket['id']?.toString() == id) return ticket;
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final ticketId = _selectedTicketId;
    final text = _messageCtrl.text.trim();
    if (ticketId == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await supportService.postMessage(
        ref.read(authProvider).accessToken,
        ticketId,
        text,
        messageKind: 'staff',
      );
      _messageCtrl.clear();
      setState(() => _messagesFuture = _loadMessages(ticketId));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _patchTicket(
    String ticketId,
    Map<String, dynamic> body,
  ) async {
    setState(() => _patching = true);
    try {
      await supportService.patchTicket(
        ref.read(authProvider).accessToken,
        ticketId,
        body,
      );
      await _refreshTickets();
      if (_selectedTicketId == ticketId) {
        setState(() => _messagesFuture = _loadMessages(ticketId));
      }
    } finally {
      if (mounted) setState(() => _patching = false);
    }
  }

  Future<void> _resolveTicket(String ticketId) {
    return _patchTicket(ticketId, {'status': 'resolved'});
  }

  Future<void> _assignToMe(String ticketId) {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return Future.value();
    return _patchTicket(ticketId, {
      'assignee_id': userId,
      'status': 'in_progress',
    });
  }

  Future<void> _escalateTicket(Map<String, dynamic> ticket) async {
    final id = ticket['id']?.toString();
    if (id == null) return;
    final nextLevel = (ticketSupportLevel(ticket) + 1).clamp(1, 3);
    await _patchTicket(id, {'support_level': nextLevel});
  }

  int _tabIndexFromSub(String? sub) {
    return sub == AdminTabs.chatSupportDrivers ? 1 : 0;
  }

  String _subFromTabIndex(int index) {
    return index == 1
        ? AdminTabs.chatSupportDrivers
        : AdminTabs.chatSupportClients;
  }

  Widget _buildFilters() {
    const controlsKey = 'chat_support';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSearchToolbar(
          value: controls.search,
          onChanged: controlsNotifier.setSearch,
          placeholder: 'Search tickets',
        ),
        const SizedBox(height: 10),
        AdminManagedListToolbarSection(
          controls: controls,
          notifier: controlsNotifier,
          selection: _selection,
          onSelectionChanged: _refreshSelection,
          sortOptions: adminEntityGridSortOptions(),
          filters: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminFilterSelect(
                value: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
                options: const [
                  AdminFilterOption(value: 'all', label: 'All status'),
                  AdminFilterOption(value: 'open', label: 'Open'),
                  AdminFilterOption(value: 'in_progress', label: 'In progress'),
                  AdminFilterOption(value: 'resolved', label: 'Resolved'),
                ],
              ),
              AdminFilterSelect(
                value: _levelFilter,
                onChanged: (v) => setState(() => _levelFilter = v),
                options: const [
                  AdminFilterOption(value: 'all', label: 'All levels'),
                  AdminFilterOption(value: '1', label: 'L1'),
                  AdminFilterOption(value: '2', label: 'L2'),
                  AdminFilterOption(value: '3', label: 'L3'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'chat_support';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final sub = GoRouterState.of(context).uri.queryParameters['sub'];
    final tabIndex = _tabIndexFromSub(sub);
    final audience = audienceFromSubTab(sub);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final mobileInThread = !isWide && _selectedTicketId != null;

    return PermissionGate(
      permissions: const ['communication:chat:reply', 'support:reply'],
      fallback: const Center(child: Text('No access to support chat.')),
      child: DefaultTabController(
        key: ValueKey(sub ?? AdminTabs.chatSupportClients),
        length: 2,
        initialIndex: tabIndex,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!mobileInThread)
                AdminPageHeader(
                  title: 'Chat Support',
                  subtitle: 'Filter, create, assign, and reply to tickets.',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showCreateSupportTicketSheet(
                          context,
                          ref,
                          audience: audience,
                          onCreated: (ticketId) {
                            _refreshTickets();
                            _selectTicket(ticketId);
                          },
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New ticket'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _refreshTickets,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              if (!mobileInThread) ...[
                const SizedBox(height: 8),
                TabBar(
                  onTap: (index) {
                    _clearTicket();
                    context.go(
                      '${Routes.adminChatSupport}?sub=${_subFromTabIndex(index)}',
                    );
                  },
                  tabs: const [
                    Tab(text: 'Clients'),
                    Tab(text: 'Drivers'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _ticketsFuture,
                  builder: (context, ticketsSnapshot) {
                    final allTickets = ticketsSnapshot.data?['tickets'] is List
                        ? (ticketsSnapshot.data!['tickets'] as List)
                              .whereType<Map>()
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(growable: false)
                        : <Map<String, dynamic>>[];
                    final tickets = filterSupportTickets(
                      allTickets,
                      audience: audience,
                      search: controls.search,
                      statusFilter: _statusFilter,
                      levelFilter: _levelFilter,
                    );
                    final sortedTickets = _sortTickets(tickets, controls);
                    final pagination = _slice.call(
                      sortedTickets,
                      adminPaginatedOptions(
                        controls: controls,
                        notifier: controlsNotifier,
                        resetDeps: [
                          controls.search,
                          controls.activeSort?.key,
                          controls.activeSort?.dir.name,
                          _statusFilter,
                          _levelFilter,
                          audience,
                          controls.layout.name,
                        ],
                      ),
                    );
                    final sliceOptions = adminPaginatedOptions(
                      controls: controls,
                      notifier: controlsNotifier,
                    );
                    final selected = _selectedTicket(tickets);

                    Widget ticketListColumn() {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _TicketListPanel(
                              loading: ticketsSnapshot.connectionState ==
                                  ConnectionState.waiting,
                              error: ticketsSnapshot.error,
                              tickets: pagination.visibleItems,
                              layout: controls.layout,
                              selection: _selection,
                              onSelectionChanged: _refreshSelection,
                              selectedTicketId: _selectedTicketId,
                              onSelectTicket: _selectTicket,
                            ),
                          ),
                          AdminManagedListFooterSection(
                            pagination: pagination,
                            notifier: controlsNotifier,
                            slice: _slice,
                            sliceOptions: sliceOptions,
                          ),
                        ],
                      );
                    }

                    if (mobileInThread) {
                      return _ChatThreadPanel(
                        ticket: selected,
                        onBack: _clearTicket,
                        messagesFuture: _messagesFuture,
                        messageCtrl: _messageCtrl,
                        sending: _sending,
                        patching: _patching,
                        onSend: _sendMessage,
                        onReloadMessages: () {
                          final id = _selectedTicketId;
                          if (id == null) return;
                          setState(() => _messagesFuture = _loadMessages(id));
                        },
                        onResolve: selected == null
                            ? null
                            : () => _resolveTicket(selected['id'].toString()),
                        onAssign: selected == null
                            ? null
                            : () => _assignToMe(selected['id'].toString()),
                        onEscalate: selected == null
                            ? null
                            : () => _escalateTicket(selected),
                      );
                    }

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(flex: 4, child: ticketListColumn()),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: _ChatThreadPanel(
                              ticket: selected,
                              messagesFuture: _messagesFuture,
                              messageCtrl: _messageCtrl,
                              sending: _sending,
                              patching: _patching,
                              onSend: _sendMessage,
                              onReloadMessages: () {
                                final id = _selectedTicketId;
                                if (id == null) return;
                                setState(
                                  () => _messagesFuture = _loadMessages(id),
                                );
                              },
                              onResolve: selected == null
                                  ? null
                                  : () =>
                                        _resolveTicket(selected['id'].toString()),
                              onAssign: selected == null
                                  ? null
                                  : () => _assignToMe(selected['id'].toString()),
                              onEscalate: selected == null
                                  ? null
                                  : () => _escalateTicket(selected),
                            ),
                          ),
                        ],
                      );
                    }

                    return ticketListColumn();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _sortTickets(
    List<Map<String, dynamic>> tickets,
    ListControlsState controls,
  ) {
    final sort = controls.activeSort;
    if (sort == null) return tickets;
    final rows = [...tickets];
    rows.sort((a, b) => compareSortable(a['updated_at'], b['updated_at'], sort.dir));
    return rows;
  }
}

class _TicketListPanel extends StatelessWidget {
  const _TicketListPanel({
    required this.loading,
    required this.error,
    required this.tickets,
    required this.layout,
    required this.selection,
    required this.onSelectionChanged,
    required this.selectedTicketId,
    required this.onSelectTicket,
  });

  final bool loading;
  final Object? error;
  final List<Map<String, dynamic>> tickets;
  final ListLayout layout;
  final BulkSelection selection;
  final VoidCallback onSelectionChanged;
  final String? selectedTicketId;
  final ValueChanged<String> onSelectTicket;

  @override
  Widget build(BuildContext context) {
    if (loading && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && tickets.isEmpty) {
      return Center(child: Text('Failed to load tickets: $error'));
    }

    return AdminLayoutSwitch(
      layout: layout,
      isEmpty: tickets.isEmpty,
      empty: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No tickets match the current filters.'),
      ),
      table: AdminTableCard(
        child: ListView.separated(
          itemCount: tickets.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final id = rowId(ticket);
            final userId = ticket['user_id']?.toString() ?? '';
            final isSelected = selectedTicketId == id;
            final level = ticketSupportLevel(ticket);
            return AdminSelectableListTile(
              id: id,
              selected: selection.isSelected(id),
              onToggleSelected: () {
                selection.toggle(id);
                onSelectionChanged();
              },
              onTap: id.isEmpty ? null : () => onSelectTicket(id),
              title: Text(
                ticket['subject']?.toString() ?? 'Untitled',
                style: isSelected ? const TextStyle(fontWeight: FontWeight.w700) : null,
              ),
              subtitle: Text(
                '${ticketUserLabel(userId)} · ${ticket['status'] ?? '—'} · L$level',
              ),
              trailing: StatusBadge(
                label: ticket['priority']?.toString() ?? 'normal',
              ),
            );
          },
        ),
      ),
      grid: AdminEntityGrid(
        children: [
          for (final ticket in tickets)
            AdminEntityGridCard(
              selected: selection.isSelected(rowId(ticket)),
              onTap: () {
                final id = rowId(ticket);
                if (id.isNotEmpty) onSelectTicket(id);
              },
              selection: AdminListSelectCheckbox(compact: true, 
                checked: selection.isSelected(rowId(ticket)),
                onChanged: () {
                  selection.toggle(rowId(ticket));
                  onSelectionChanged();
                },
              ),
              child: Text(ticket['subject']?.toString() ?? 'Untitled'),
            ),
        ],
      ),
    );
  }
}

class _ChatThreadPanel extends StatelessWidget {
  const _ChatThreadPanel({
    required this.ticket,
    this.onBack,
    required this.messagesFuture,
    required this.messageCtrl,
    required this.sending,
    required this.patching,
    required this.onSend,
    required this.onReloadMessages,
    this.onResolve,
    this.onAssign,
    this.onEscalate,
  });

  final Map<String, dynamic>? ticket;
  final VoidCallback? onBack;
  final Future<Map<String, dynamic>>? messagesFuture;
  final TextEditingController messageCtrl;
  final bool sending;
  final bool patching;
  final VoidCallback onSend;
  final VoidCallback onReloadMessages;
  final VoidCallback? onResolve;
  final VoidCallback? onAssign;
  final VoidCallback? onEscalate;

  bool get _resolved =>
      ticket != null &&
      normTicketStatus(ticket!['status']?.toString() ?? '') == 'resolved';

  @override
  Widget build(BuildContext context) {
    final ticketId = ticket?['id']?.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Tickets'),
              ),
            ),
          if (ticket != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket!['subject']?.toString() ?? 'Ticket',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onAssign != null && !_resolved)
                        OutlinedButton(
                          onPressed: patching ? null : onAssign,
                          child: const Text('Assign to me'),
                        ),
                      if (onEscalate != null &&
                          !_resolved &&
                          ticketSupportLevel(ticket!) < 3)
                        OutlinedButton(
                          onPressed: patching ? null : onEscalate,
                          child: Text(
                            'Escalate to L${ticketSupportLevel(ticket!) + 1}',
                          ),
                        ),
                      if (onResolve != null && !_resolved)
                        FilledButton(
                          onPressed: patching ? null : onResolve,
                          child: const Text('Resolve'),
                        ),
                      if (_resolved)
                        const StatusBadge(
                          label: 'Resolved',
                          variant: StatusBadgeVariant.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ticketId == null
                ? const Center(child: Text('Select a ticket to open chat.'))
                : FutureBuilder<Map<String, dynamic>>(
                    future: messagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Failed to load messages: ${snapshot.error}'),
                        );
                      }
                      final raw = snapshot.data?['messages'];
                      final messages = raw is List
                          ? raw
                                .whereType<Map>()
                                .map((e) => Map<String, dynamic>.from(e))
                                .toList(growable: false)
                          : <Map<String, dynamic>>[];
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages in this ticket.'));
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          final kind = message['message_kind']?.toString() ?? 'user';
                          final isStaff = kind == 'staff';
                          return Align(
                            alignment: isStaff
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                color: isStaff
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(message['body']?.toString() ?? ''),
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
                if (ticketId != null)
                  IconButton(
                    tooltip: 'Reload messages',
                    onPressed: onReloadMessages,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                Expanded(
                  child: TextField(
                    controller: messageCtrl,
                    minLines: 1,
                    maxLines: 3,
                    enabled: ticketId != null && !_resolved,
                    decoration: const InputDecoration(
                      hintText: 'Reply to ticket...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed:
                      ticketId != null && !_resolved && !sending ? onSend : null,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
