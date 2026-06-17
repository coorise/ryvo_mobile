import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/services/index.dart';

class PortalEphemeralChatPanel extends ConsumerStatefulWidget {
  const PortalEphemeralChatPanel({super.key});

  @override
  ConsumerState<PortalEphemeralChatPanel> createState() => _PortalEphemeralChatPanelState();
}

class _PortalEphemeralChatPanelState extends ConsumerState<PortalEphemeralChatPanel> {
  final _draftController = TextEditingController();
  Timer? _polling;
  bool _loading = true;
  String? _error;
  String? _tripId;
  List<Map<String, dynamic>> _messages = const [];
  String? _phase;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      if (!apiClientTestMode) {
        _polling = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    _draftController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final auth = useAuth(ref);
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final active = await tripService.getActiveTrip(auth.accessToken);
      final phase = portalStr(active['phase'], '');
      final trip = active['trip'];
      final tripId = trip is Map ? portalStr(trip['id'], '') : '';
      List<Map<String, dynamic>> messages = const [];
      if (tripId.isNotEmpty && phase == 'active_trip') {
        final msgRes = await tripChatService.listMessages(auth.accessToken, tripId);
        messages = portalMapList(msgRes, 'messages');
      }
      if (!mounted) return;
      setState(() {
        _phase = phase;
        _tripId = tripId.isEmpty ? null : tripId;
        _messages = messages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.chat.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final body = _draftController.text.trim();
    final tripId = _tripId;
    if (body.isEmpty || tripId == null || _sending) return;
    final auth = useAuth(ref);
    setState(() => _sending = true);
    try {
      await tripChatService.sendMessage(auth.accessToken, tripId, body);
      _draftController.clear();
      await _load(silent: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    if (_tripId == null || _phase != 'active_trip') {
      return portalEmpty(T.portal('portal.chat.empty'));
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final mine = portalStr(message['sender_id'], '') == portalStr(useAuth(ref).user?.id, '');
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: mine
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      portalStr(message['body']),
                      style: TextStyle(
                        color: mine ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _draftController,
                    placeholder: Text(T.portal('portal.chat.inputPlaceholder')),
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _sending ? null : _send,
                  child: const Icon(LucideIcons.send, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
