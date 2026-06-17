import 'package:flutter/material.dart';

import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/i18n/t.dart';

List<Map<String, dynamic>> portalMapList(dynamic root, String key) {
  if (root is! Map) return const [];
  final value = root[key];
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

String portalStr(dynamic value, [String fallback = '—']) {
  if (value == null) return fallback;
  final s = value.toString();
  return s.isEmpty ? fallback : s;
}

StatusBadgeVariant portalTripStatus(String status) {
  if (status == 'completed') return StatusBadgeVariant.success;
  if (status == 'cancelled' || status == 'canceled') return StatusBadgeVariant.danger;
  if (status == 'in_progress' || status == 'active') return StatusBadgeVariant.warning;
  return StatusBadgeVariant.defaultVariant;
}

StatusBadgeVariant portalPaymentStatus(String status) {
  if (status == 'succeeded') return StatusBadgeVariant.success;
  if (status == 'pending' || status == 'processing') return StatusBadgeVariant.warning;
  if (status == 'failed' || status == 'cancelled' || status == 'canceled') {
    return StatusBadgeVariant.danger;
  }
  return StatusBadgeVariant.defaultVariant;
}

Widget portalLoading() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text(T.nav('common.loading'))),
    );

Widget portalError(String message) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );

Widget portalEmpty(String message) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
