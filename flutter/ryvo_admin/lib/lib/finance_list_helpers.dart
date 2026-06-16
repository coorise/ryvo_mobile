import 'package:flutter/material.dart';

List<Map<String, dynamic>> financeRows(
  dynamic payload, {
  List<String> keys = const [],
}) {
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
  if (payload is Map) {
    final map = Map<String, dynamic>.from(payload);
    for (final key in keys) {
      final raw = map[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
    }
  }
  return const [];
}

Map<String, dynamic> defaultTariffBody({
  String? name,
  String? code,
  num? commissionPercent,
  bool active = true,
}) {
  return {
    'code': code ?? '',
    'name': name ?? '',
    'package_type': 'custom',
    'description': '',
    'commission_percent': commissionPercent ?? 20,
    'subscription_monthly': null,
    'recurrence_count': null,
    'recurrence_unlimited': true,
    'valid_until': null,
    'valid_unlimited': true,
    'min_withdraw_amount': 25,
    'max_withdraw_amount': null,
    'max_withdraw_unlimited': true,
    'payout_label': 'instant',
    'payout_delay_minutes': 0,
    'payout_delay_days': 0,
    'payout_custom_label': 'Instant',
    'payout_cadence': 'instant',
    'quota_trips': null,
    'discount_percent': 0,
    'search_boost': 0,
    'is_optional_subscription': false,
    'billing_mode': 'subscription',
    'is_basic': false,
    'is_system': false,
    'active': active,
    'features': {
      'priority_dispatch': false,
      'heat_map': false,
      'analytics': false,
      'support_priority': false,
    },
    'card_display': {
      'background_color': null,
      'badge': {'text': '', 'position': 'top-right', 'visible': false},
      'text_styles': {},
    },
  };
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  String message = 'This action cannot be undone.',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  return ok == true;
}
