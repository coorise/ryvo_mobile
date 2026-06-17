import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/lib/finance_list_helpers.dart';
import 'package:ryvo_admin/services/finance_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

Future<bool?> showTariffEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TariffEditorSheet(existing: existing),
  );
}

class _TariffEditorSheet extends ConsumerStatefulWidget {
  const _TariffEditorSheet({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_TariffEditorSheet> createState() => _TariffEditorSheetState();
}

class _TariffEditorSheetState extends ConsumerState<_TariffEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _commissionCtrl;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name']?.toString() ?? '');
    _codeCtrl = TextEditingController(text: e?['code']?.toString() ?? '');
    _commissionCtrl = TextEditingController(
      text: '${e?['commission_percent'] ?? 20}',
    );
    _active = e?['active'] != false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final token = ref.read(authProvider).accessToken;
      final commission = num.tryParse(_commissionCtrl.text.trim()) ?? 20;
      if (widget.existing != null) {
        final id = widget.existing!['id']?.toString() ?? '';
        final body = Map<String, dynamic>.from(widget.existing!);
        body['name'] = name;
        body['code'] = _codeCtrl.text.trim();
        body['commission_percent'] = commission;
        body['active'] = _active;
        await financeService.updateTariff(token, id, body);
      } else {
        await financeService.createTariff(
          token,
          defaultTariffBody(
            name: name,
            code: _codeCtrl.text.trim(),
            commissionPercent: commission,
            active: _active,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save tariff: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
              isEdit ? 'Edit tariff' : 'New tariff',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commissionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Commission %',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Save changes' : 'Create tariff'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showPaycheckCreateSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _PaycheckCreateSheet(),
  );
}

class _PaycheckCreateSheet extends ConsumerStatefulWidget {
  const _PaycheckCreateSheet();

  @override
  ConsumerState<_PaycheckCreateSheet> createState() => _PaycheckCreateSheetState();
}

class _PaycheckCreateSheetState extends ConsumerState<_PaycheckCreateSheet> {
  final _driverCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _driverCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final driverId = _driverCtrl.text.trim();
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (driverId.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver ID and amount are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await financeService.createPaycheck(
        ref.read(authProvider).accessToken,
        {
          'driver_id': driverId,
          'amount': amount,
          'period_label': 'Withdrawal',
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create paycheck: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New paycheck', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _driverCtrl,
            decoration: const InputDecoration(labelText: 'Driver ID', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create paycheck'),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showCouponEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CouponEditorSheet(existing: existing),
  );
}

class _CouponEditorSheet extends ConsumerStatefulWidget {
  const _CouponEditorSheet({this.existing});

  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_CouponEditorSheet> createState() => _CouponEditorSheetState();
}

class _CouponEditorSheetState extends ConsumerState<_CouponEditorSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _bonusCtrl;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?['code']?.toString() ?? '');
    _bonusCtrl = TextEditingController(text: '${e?['bonus_cad'] ?? 0}');
    _active = e?['active'] != false;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final bonus = num.tryParse(_bonusCtrl.text.trim());
    if (code.isEmpty || bonus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code and bonus amount are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final token = ref.read(authProvider).accessToken;
      final body = {
        'code': code,
        'bonus_cad': bonus,
        'starts_at': widget.existing?['starts_at'],
        'ends_at': widget.existing?['ends_at'],
        'active': _active,
      };
      if (widget.existing != null) {
        await financeService.updateCoupon(
          token,
          widget.existing!['id']?.toString() ?? '',
          body,
        );
      } else {
        await financeService.createCoupon(token, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save coupon: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'New coupon' : 'Edit coupon',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bonusCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Bonus (CAD)', border: OutlineInputBorder()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save coupon'),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showBonusEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? existing,
  required bool isDriver,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _BonusEditorSheet(existing: existing, isDriver: isDriver),
  );
}

class _BonusEditorSheet extends ConsumerStatefulWidget {
  const _BonusEditorSheet({this.existing, required this.isDriver});

  final Map<String, dynamic>? existing;
  final bool isDriver;

  @override
  ConsumerState<_BonusEditorSheet> createState() => _BonusEditorSheetState();
}

class _BonusEditorSheetState extends ConsumerState<_BonusEditorSheet> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _channelCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _emailCtrl = TextEditingController(text: e?['email']?.toString() ?? '');
    _balanceCtrl = TextEditingController(text: '${e?['balance'] ?? 0}');
    _channelCtrl = TextEditingController(text: e?['channel']?.toString() ?? 'wallet');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _balanceCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = num.tryParse(_balanceCtrl.text.trim());
    if (balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final token = ref.read(authProvider).accessToken;
      if (widget.existing != null) {
        await financeService.updateBonus(
          token,
          widget.existing!['id']?.toString() ?? '',
          {
            'channel': _channelCtrl.text.trim(),
            'balance': balance,
          },
        );
      } else {
        final email = _emailCtrl.text.trim();
        if (email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is required.')),
          );
          return;
        }
        await financeService.createBonus(token, {
          'email': email,
          'account_type': widget.isDriver ? 'driver' : 'client',
          'channel': _channelCtrl.text.trim(),
          'balance': balance,
        });
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save bonus: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'New bonus account' : 'Edit bonus',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (widget.existing == null)
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
          if (widget.existing == null) const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Balance', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _channelCtrl,
            decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save bonus'),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showDriverEarningActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> row,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _DriverEarningActionsSheet(row: row),
  );
}

class _DriverEarningActionsSheet extends ConsumerStatefulWidget {
  const _DriverEarningActionsSheet({required this.row});

  final Map<String, dynamic> row;

  @override
  ConsumerState<_DriverEarningActionsSheet> createState() =>
      _DriverEarningActionsSheetState();
}

class _DriverEarningActionsSheetState extends ConsumerState<_DriverEarningActionsSheet> {
  final _adjustCtrl = TextEditingController();
  final _queueCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _adjustCtrl.dispose();
    _queueCtrl.dispose();
    super.dispose();
  }

  String get _driverId =>
      widget.row['driver_id']?.toString() ?? widget.row['id']?.toString() ?? '';

  Future<void> _adjust() async {
    final delta = num.tryParse(_adjustCtrl.text.trim());
    if (delta == null || _driverId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await financeService.adjustDriverEarning(
        ref.read(authProvider).accessToken,
        _driverId,
        {'delta': delta, 'reason': 'Admin adjustment'},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adjust failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _queuePaycheck() async {
    final amount = double.tryParse(_queueCtrl.text.trim());
    if (amount == null || _driverId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await financeService.queuePaycheckFromEarnings(
        ref.read(authProvider).accessToken,
        _driverId,
        amount,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue paycheck failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Driver earnings', style: Theme.of(context).textTheme.titleLarge),
          Text('Driver: $_driverId'),
          const SizedBox(height: 12),
          TextField(
            controller: _adjustCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Adjust delta (+/-)',
              border: OutlineInputBorder(),
            ),
          ),
          OutlinedButton(onPressed: _busy ? null : _adjust, child: const Text('Apply adjustment')),
          const SizedBox(height: 12),
          TextField(
            controller: _queueCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Queue paycheck amount',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton(onPressed: _busy ? null : _queuePaycheck, child: const Text('Queue paycheck')),
        ],
      ),
    );
  }
}

Future<bool?> showCheckoutRecoverySheet(
  BuildContext context,
  WidgetRef ref,
  String checkoutId,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CheckoutRecoverySheet(checkoutId: checkoutId),
  );
}

class _CheckoutRecoverySheet extends ConsumerStatefulWidget {
  const _CheckoutRecoverySheet({required this.checkoutId});

  final String checkoutId;

  @override
  ConsumerState<_CheckoutRecoverySheet> createState() => _CheckoutRecoverySheetState();
}

class _CheckoutRecoverySheetState extends ConsumerState<_CheckoutRecoverySheet> {
  final _messageCtrl = TextEditingController(
    text: 'Please complete your pending checkout.',
  );
  String _channel = 'email';
  bool _saving = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await financeService.scheduleCheckoutRecovery(
        ref.read(authProvider).accessToken,
        widget.checkoutId,
        {
          'channel': _channel,
          'message': _messageCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recovery reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'sms', child: Text('SMS')),
              DropdownMenuItem(value: 'push', child: Text('Push')),
            ],
            onChanged: (v) => setState(() => _channel = v ?? 'email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Schedule reminder'),
          ),
        ],
      ),
    );
  }
}
