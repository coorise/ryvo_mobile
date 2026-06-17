import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/settings/settings_form_card.dart';
import 'package:ryvo_admin/components/admin/settings/settings_profile_header.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class SettingsGeneralTab extends ConsumerStatefulWidget {
  const SettingsGeneralTab({super.key});

  @override
  ConsumerState<SettingsGeneralTab> createState() =>
      _SettingsGeneralTabState();
}

class _SettingsGeneralTabState extends ConsumerState<SettingsGeneralTab> {
  final _appName = TextEditingController(text: AppConst.appName);
  final _timeZone = TextEditingController(text: 'America/Toronto');
  final _supportEmail = TextEditingController();
  final _maxRadius = TextEditingController(text: '50');
  final _cancelWindow = TextEditingController(text: '5');
  final _maintenanceMsg = TextEditingController();
  String _defaultLanguage = 'en';
  bool _scheduledRides = true;
  bool _maintenanceMode = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _appName.dispose();
    _timeZone.dispose();
    _supportEmail.dispose();
    _maxRadius.dispose();
    _cancelWindow.dispose();
    _maintenanceMsg.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await settingsService.getGeneral(
        ref.read(authProvider).accessToken,
      );
      final prefs = res['preferences'] is Map
          ? Map<String, dynamic>.from(res['preferences'] as Map)
          : <String, dynamic>{};
      _appName.text = prefs['appName']?.toString() ?? AppConst.appName;
      _timeZone.text = prefs['timeZone']?.toString() ?? 'America/Toronto';
      _supportEmail.text = prefs['supportEmail']?.toString() ?? '';
      _maxRadius.text = '${prefs['maxSearchRadiusKm'] ?? 50}';
      _cancelWindow.text = '${prefs['cancelWindowMinutes'] ?? 5}';
      _maintenanceMsg.text = prefs['maintenanceMessage']?.toString() ?? '';
      _defaultLanguage = prefs['defaultLanguage']?.toString() ?? 'en';
      _scheduledRides = prefs['scheduledRideEnabled'] != false;
      _maintenanceMode = prefs['maintenanceMode'] == true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await settingsService.updateGeneral(
        ref.read(authProvider).accessToken,
        {
          'appName': _appName.text.trim(),
          'timeZone': _timeZone.text.trim(),
          'defaultLanguage': _defaultLanguage,
          'supportedLanguages': AppConst.supportedLanguages,
          'supportEmail': _supportEmail.text.trim(),
          'maxSearchRadiusKm': int.tryParse(_maxRadius.text.trim()) ?? 50,
          'cancelWindowMinutes': int.tryParse(_cancelWindow.text.trim()) ?? 5,
          'scheduledRideEnabled': _scheduledRides,
          'maintenanceMode': _maintenanceMode,
          'maintenanceMessage': _maintenanceMsg.text.trim(),
        },
      );
      messenger.showSnackBar(const SnackBar(content: Text('General settings saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Abac.canEditSettingsTab(useAuth(ref).user, 'general');
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SettingsFormCard(
      title: 'General',
      description: 'Platform name, locale, ride rules, and maintenance.',
      saving: _saving,
      disabled: !canEdit,
      onSave: canEdit ? _save : null,
      child: Column(
        children: [
          SettingsTextField(label: 'App name', controller: _appName, enabled: canEdit),
          const SizedBox(height: 12),
          SettingsTextField(label: 'Time zone', controller: _timeZone, enabled: canEdit),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _defaultLanguage,
            decoration: const InputDecoration(
              labelText: 'Default language',
              border: OutlineInputBorder(),
            ),
            items: AppConst.supportedLanguages
                .map((lng) => DropdownMenuItem(value: lng, child: Text(lng.toUpperCase())))
                .toList(),
            onChanged: canEdit ? (v) => setState(() => _defaultLanguage = v ?? 'en') : null,
          ),
          const SizedBox(height: 12),
          SettingsTextField(label: 'Support email', controller: _supportEmail, enabled: canEdit),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Max search radius (km)',
            controller: _maxRadius,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Cancel window (minutes)',
            controller: _cancelWindow,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SettingsSwitchRow(
            title: 'Scheduled rides',
            subtitle: 'Allow users to book rides in advance.',
            value: _scheduledRides,
            enabled: canEdit,
            onChanged: (v) => setState(() => _scheduledRides = v),
          ),
          const SizedBox(height: 8),
          SettingsSwitchRow(
            title: 'Maintenance mode',
            subtitle: 'Block new trips and show maintenance message.',
            value: _maintenanceMode,
            enabled: canEdit,
            onChanged: (v) => setState(() => _maintenanceMode = v),
          ),
          if (_maintenanceMode) ...[
            const SizedBox(height: 12),
            SettingsTextField(
              label: 'Maintenance message',
              controller: _maintenanceMsg,
              enabled: canEdit,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsPaymentTab extends ConsumerStatefulWidget {
  const SettingsPaymentTab({super.key});

  @override
  ConsumerState<SettingsPaymentTab> createState() => _SettingsPaymentTabState();
}

class _SettingsPaymentTabState extends ConsumerState<SettingsPaymentTab> {
  final _currency = TextEditingController(text: 'CAD');
  final _platformFee = TextEditingController(text: '20');
  final _payoutDelay = TextEditingController(text: '2');
  final _minFare = TextEditingController(text: '5');
  final _cancelFee = TextEditingController(text: '5');
  final _publishableKey = TextEditingController();
  String _stripeMode = 'test';
  bool _autoCapture = true;
  bool _tipsEnabled = true;
  bool _requirePreauth = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _currency.dispose();
    _platformFee.dispose();
    _payoutDelay.dispose();
    _minFare.dispose();
    _cancelFee.dispose();
    _publishableKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await settingsService.getPayment(
        ref.read(authProvider).accessToken,
      );
      final config = res['config'] is Map
          ? Map<String, dynamic>.from(res['config'] as Map)
          : <String, dynamic>{};
      _currency.text = config['currency']?.toString() ?? 'CAD';
      _stripeMode = config['stripeMode']?.toString() ?? 'test';
      _publishableKey.text = config['stripePublishableKey']?.toString() ?? '';
      _platformFee.text = '${config['platformFeePercent'] ?? 20}';
      _payoutDelay.text = '${config['driverPayoutDelayDays'] ?? 2}';
      _minFare.text = '${config['minTripFare'] ?? 5}';
      _cancelFee.text = '${config['cancellationFee'] ?? 5}';
      _autoCapture = config['autoCapture'] != false;
      _tipsEnabled = config['tipsEnabled'] != false;
      _requirePreauth = config['requirePreauth'] != false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await settingsService.updatePayment(
        ref.read(authProvider).accessToken,
        {
          'currency': _currency.text.trim().toUpperCase(),
          'stripeMode': _stripeMode,
          'stripePublishableKey': _publishableKey.text.trim(),
          'platformFeePercent': double.tryParse(_platformFee.text.trim()) ?? 20,
          'driverPayoutDelayDays':
              int.tryParse(_payoutDelay.text.trim()) ?? 2,
          'minTripFare': double.tryParse(_minFare.text.trim()) ?? 5,
          'cancellationFee': double.tryParse(_cancelFee.text.trim()) ?? 5,
          'autoCapture': _autoCapture,
          'tipsEnabled': _tipsEnabled,
          'requirePreauth': _requirePreauth,
        },
      );
      messenger.showSnackBar(const SnackBar(content: Text('Payment settings saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Abac.canEditSettingsTab(useAuth(ref).user, 'payment');
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SettingsFormCard(
      title: 'Payment',
      description: 'Stripe mode, fees, and trip payment rules.',
      saving: _saving,
      disabled: !canEdit,
      onSave: canEdit ? _save : null,
      child: Column(
        children: [
          SettingsTextField(label: 'Currency', controller: _currency, enabled: canEdit),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stripeMode,
            decoration: const InputDecoration(
              labelText: 'Stripe mode',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'test', child: Text('Test')),
              DropdownMenuItem(value: 'live', child: Text('Live')),
            ],
            onChanged: canEdit ? (v) => setState(() => _stripeMode = v ?? 'test') : null,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Publishable key',
            controller: _publishableKey,
            enabled: canEdit,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Platform fee (%)',
            controller: _platformFee,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Driver payout delay (days)',
            controller: _payoutDelay,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Minimum trip fare',
            controller: _minFare,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            label: 'Cancellation fee',
            controller: _cancelFee,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          SettingsSwitchRow(
            title: 'Auto capture',
            subtitle: 'Capture payments automatically after trip.',
            value: _autoCapture,
            enabled: canEdit,
            onChanged: (v) => setState(() => _autoCapture = v),
          ),
          SettingsSwitchRow(
            title: 'Tips enabled',
            subtitle: 'Allow riders to tip drivers.',
            value: _tipsEnabled,
            enabled: canEdit,
            onChanged: (v) => setState(() => _tipsEnabled = v),
          ),
          SettingsSwitchRow(
            title: 'Require pre-authorization',
            subtitle: 'Hold funds before driver accepts.',
            value: _requirePreauth,
            enabled: canEdit,
            onChanged: (v) => setState(() => _requirePreauth = v),
          ),
        ],
      ),
    );
  }
}

class SettingsMailTab extends ConsumerStatefulWidget {
  const SettingsMailTab({super.key});

  @override
  ConsumerState<SettingsMailTab> createState() => _SettingsMailTabState();
}

class _SettingsMailTabState extends ConsumerState<SettingsMailTab> {
  List<Map<String, dynamic>> _templates = const [];
  Map<String, dynamic>? _draft;
  final _subjectCtrl = TextEditingController();
  final _bodyHtmlCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyHtmlCtrl.dispose();
    super.dispose();
  }

  void _selectDraft(Map<String, dynamic> tpl) {
    setState(() {
      _draft = Map<String, dynamic>.from(tpl);
      _subjectCtrl.text = tpl['subject']?.toString() ?? '';
      _bodyHtmlCtrl.text = tpl['body_html']?.toString() ?? '';
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await settingsService.listEmailTemplates(
        ref.read(authProvider).accessToken,
      );
      final raw = res['templates'];
      _templates = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (_templates.isNotEmpty) {
        _selectDraft(_templates.first);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final key = draft['template_key']?.toString();
    if (key == null || key.isEmpty) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await settingsService.updateEmailTemplate(
        ref.read(authProvider).accessToken,
        key,
        {
          'subject': _subjectCtrl.text.trim(),
          'body_html': _bodyHtmlCtrl.text.trim(),
          'body_text': draft['body_text']?.toString() ?? '',
        },
      );
      messenger.showSnackBar(const SnackBar(content: Text('Template saved.')));
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Abac.canEditSettingsTab(useAuth(ref).user, 'mail');
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_templates.isEmpty) {
      return const Center(child: Text('No email templates.'));
    }

    final draft = _draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tpl = _templates[index];
              final key = tpl['template_key']?.toString() ?? '';
              final selected = draft?['template_key']?.toString() == key;
              return ChoiceChip(
                label: Text(key),
                selected: selected,
                onSelected: (_) => _selectDraft(tpl),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (draft != null)
          SettingsFormCard(
            title: draft['template_key']?.toString() ?? 'Template',
            description: 'Edit subject and HTML body.',
            saving: _saving,
            disabled: !canEdit,
            onSave: canEdit ? _save : null,
            child: Column(
              children: [
                SettingsTextField(
                  label: 'Subject',
                  controller: _subjectCtrl,
                  enabled: canEdit,
                ),
                const SizedBox(height: 12),
                SettingsTextField(
                  label: 'Body HTML',
                  controller: _bodyHtmlCtrl,
                  enabled: canEdit,
                  maxLines: 8,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SettingsNotificationsTab extends ConsumerStatefulWidget {
  const SettingsNotificationsTab({super.key});

  @override
  ConsumerState<SettingsNotificationsTab> createState() =>
      _SettingsNotificationsTabState();
}

class _SettingsNotificationsTabState extends ConsumerState<SettingsNotificationsTab> {
  List<Map<String, dynamic>> _events = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await settingsService.getNotifications(
        ref.read(authProvider).accessToken,
      );
      final config = res['config'] is Map
          ? Map<String, dynamic>.from(res['config'] as Map)
          : <String, dynamic>{};
      final raw = config['events'];
      _events = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await settingsService.updateNotifications(
        ref.read(authProvider).accessToken,
        _events,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Notification rules saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _patchEvent(int index, Map<String, dynamic> patch) {
    setState(() {
      _events = _events
          .asMap()
          .entries
          .map((e) => e.key == index ? {...e.value, ...patch} : e.value)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Abac.canEditSettingsTab(useAuth(ref).user, 'notifications');
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SettingsFormCard(
      title: 'Notifications',
      description: 'Event channels for push, email, and SMS.',
      saving: _saving,
      disabled: !canEdit,
      onSave: canEdit ? _save : null,
      child: Column(
        children: _events.asMap().entries.map((entry) {
          final index = entry.key;
          final ev = entry.value;
          final channels = ev['channels'] is Map
              ? Map<String, dynamic>.from(ev['channels'] as Map)
              : <String, dynamic>{};
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev['key']?.toString() ?? 'event',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: ev['enabled'] == true,
                        onChanged: canEdit
                            ? (v) => _patchEvent(index, {'enabled': v})
                            : null,
                      ),
                    ],
                  ),
                  if (ev['enabled'] == true)
                    ...['push', 'email', 'sms'].map((ch) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(ch.toUpperCase()),
                        value: channels[ch] == true,
                        onChanged: canEdit
                            ? (v) {
                                final next = Map<String, dynamic>.from(channels);
                                next[ch] = v;
                                _patchEvent(index, {'channels': next});
                              }
                            : null,
                      );
                    }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SettingsProfileForm extends ConsumerStatefulWidget {
  const SettingsProfileForm({super.key});

  @override
  ConsumerState<SettingsProfileForm> createState() => _SettingsProfileFormState();
}

class _SettingsProfileFormState extends ConsumerState<SettingsProfileForm> {
  final _avatarUrl = TextEditingController();
  final _fullName = TextEditingController();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController();
  final _bio = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _avatarUrl.dispose();
    _fullName.dispose();
    _displayName.dispose();
    _username.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    _country.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await settingsService.getMyProfile(
        ref.read(authProvider).accessToken,
      );
      final profile = res['profile'] is Map
          ? Map<String, dynamic>.from(res['profile'] as Map)
          : <String, dynamic>{};
      _email = profile['email']?.toString() ?? '';
      _avatarUrl.text = profile['avatar_url']?.toString() ?? '';
      _fullName.text = profile['full_name']?.toString() ?? '';
      _displayName.text = profile['display_name']?.toString() ?? '';
      _username.text = profile['username']?.toString() ?? '';
      _phone.text = profile['phone']?.toString() ?? '';
      _address.text = profile['address_line1']?.toString() ?? '';
      _city.text = profile['city']?.toString() ?? '';
      _region.text = profile['region']?.toString() ?? '';
      _postal.text = profile['postal_code']?.toString() ?? '';
      _country.text = profile['country']?.toString() ?? '';
      _bio.text = profile['bio']?.toString() ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await settingsService.updateMyProfile(
        ref.read(authProvider).accessToken,
        {
          'avatar_url': _avatarUrl.text.trim().isEmpty ? null : _avatarUrl.text.trim(),
          'full_name': _fullName.text.trim(),
          'display_name': _displayName.text.trim(),
          'username': _username.text.trim(),
          'phone': _phone.text.trim(),
          'address_line1': _address.text.trim(),
          'city': _city.text.trim(),
          'region': _region.text.trim(),
          'postal_code': _postal.text.trim(),
          'country': _country.text.trim(),
          'bio': _bio.text.trim(),
        },
      );
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final displayName = _displayName.text.isNotEmpty
        ? _displayName.text
        : (_fullName.text.isNotEmpty ? _fullName.text : _email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsProfileHeader(
          displayName: displayName,
          email: _email,
          avatarUrl: _avatarUrl.text.trim().isEmpty ? null : _avatarUrl.text.trim(),
        ),
        const SizedBox(height: 24),
        SettingsFormCard(
          title: 'Edit profile',
          description: 'Photo, name, contact, and address shown on your admin account.',
          saving: _saving,
          onSave: _save,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;

              Widget pair(Widget left, Widget right) {
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 16), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 16),
                    Expanded(child: right),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsTextField(
                    label: 'Profile photo URL',
                    controller: _avatarUrl,
                    hintText: 'https://…',
                  ),
                  const SizedBox(height: 16),
                  pair(
                    SettingsTextField(label: 'Full name', controller: _fullName),
                    SettingsTextField(label: 'Display name', controller: _displayName),
                  ),
                  const SizedBox(height: 16),
                  pair(
                    SettingsTextField(label: 'Username', controller: _username),
                    SettingsTextField(label: 'Phone', controller: _phone),
                  ),
                  const SizedBox(height: 16),
                  SettingsTextField(label: 'Street address', controller: _address),
                  const SizedBox(height: 16),
                  pair(
                    SettingsTextField(label: 'City', controller: _city),
                    SettingsTextField(label: 'Province / state', controller: _region),
                  ),
                  const SizedBox(height: 16),
                  pair(
                    SettingsTextField(label: 'Postal code', controller: _postal),
                    SettingsTextField(label: 'Country (ISO)', controller: _country),
                  ),
                  const SizedBox(height: 16),
                  SettingsTextField(label: 'Bio', controller: _bio, maxLines: 3),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
