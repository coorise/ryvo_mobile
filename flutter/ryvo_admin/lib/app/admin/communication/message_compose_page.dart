import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/services/messages_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class MessageComposePage extends ConsumerStatefulWidget {
  const MessageComposePage({super.key, this.campaignId});

  final String? campaignId;

  bool get isEdit => campaignId != null && campaignId!.isNotEmpty;

  @override
  ConsumerState<MessageComposePage> createState() =>
      _MessageComposePageState();
}

class _MessageComposePageState extends ConsumerState<MessageComposePage> {
  final _messageCtrl = TextEditingController();
  String _audience = 'clients';
  bool _sendPush = true;
  bool _sendEmail = false;
  int _delayMinutes = 0;
  bool _submitting = false;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadCampaign();
    }
  }

  Future<void> _loadCampaign() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final token = ref.read(authProvider).accessToken;
      final res = await messagesService.getById(token, widget.campaignId!);
      final campaign = res['campaign'];
      if (campaign is! Map) {
        setState(() => _loadError = 'Campaign not found.');
        return;
      }
      final map = Map<String, dynamic>.from(campaign);
      _messageCtrl.text = map['body_template']?.toString() ?? '';
      _audience = map['audience']?.toString() ?? 'clients';
      _sendPush = map['send_push'] == true;
      _sendEmail = map['send_email'] == true;
      _delayMinutes = (map['delay_minutes'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload({required String status}) {
    return {
      'audience': _audience,
      'body_template': _messageCtrl.text.trim(),
      'send_push': _sendPush,
      'send_email': _sendEmail,
      'delay_minutes': _delayMinutes,
      'status': status,
    };
  }

  bool _validate() {
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message body is required.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveDraft() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (widget.isEdit) {
        await messagesService.update(
          token,
          widget.campaignId!,
          _payload(status: 'draft'),
        );
      } else {
        await messagesService.create(token, _payload(status: 'draft'));
      }
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Draft saved successfully.')),
      );
      context.go(Routes.adminCommMessages);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save draft: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendNow() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);
    final status = _delayMinutes > 0 ? 'queued' : 'sent';

    try {
      if (widget.isEdit) {
        await messagesService.update(
          token,
          widget.campaignId!,
          _payload(status: status),
        );
        if (status == 'sent') {
          await messagesService.send(token, widget.campaignId!);
        }
      } else {
        await messagesService.create(token, _payload(status: status));
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _delayMinutes > 0
                ? 'Message scheduled successfully.'
                : 'Message sent successfully.',
          ),
        ),
      );
      context.go(Routes.adminCommMessages);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: widget.isEdit
          ? const ['communication:messages:update', 'support:reply']
          : const ['communication:messages:create', 'support:reply'],
      fallback: const Center(
        child: Text('You do not have access to compose messages.'),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Text(_loadError!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: AdminListStack(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.adminCommMessages),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to messages'),
              ),
              AdminPageHeader(
                title: widget.isEdit ? 'Edit message' : 'Compose message',
                subtitle: widget.isEdit
                    ? 'Update an existing campaign.'
                    : 'Create a new campaign for clients or drivers.',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audience',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _AudienceChip(
                            label: 'Clients',
                            selected: _audience == 'clients',
                            onTap: () => setState(() => _audience = 'clients'),
                          ),
                          _AudienceChip(
                            label: 'Drivers',
                            selected: _audience == 'drivers',
                            onTap: () => setState(() => _audience = 'drivers'),
                          ),
                          _AudienceChip(
                            label: 'Everyone',
                            selected: _audience == 'all',
                            onTap: () => setState(() => _audience = 'all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Message body',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _messageCtrl.text.trim().isEmpty
                              ? 'Preview will appear here.'
                              : _messageCtrl.text.trim(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Send push notification'),
                        value: _sendPush,
                        onChanged: (v) => setState(() => _sendPush = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Send email'),
                        value: _sendEmail,
                        onChanged: (v) => setState(() => _sendEmail = v),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: '0',
                        decoration: const InputDecoration(
                          labelText: 'Delay (minutes)',
                          helperText: '0 sends immediately when not a draft.',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            _delayMinutes = int.tryParse(v.trim()) ?? 0,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => context.go(Routes.adminCommMessages),
                            child: const Text('Cancel'),
                          ),
                          OutlinedButton(
                            onPressed: _submitting ? null : _saveDraft,
                            child: Text(
                              _submitting ? 'Saving...' : 'Save draft',
                            ),
                          ),
                          FilledButton(
                            onPressed: _submitting ? null : _sendNow,
                            child: Text(
                              _submitting
                                  ? 'Working...'
                                  : (_delayMinutes <= 0
                                        ? 'Send now'
                                        : 'Schedule'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}
