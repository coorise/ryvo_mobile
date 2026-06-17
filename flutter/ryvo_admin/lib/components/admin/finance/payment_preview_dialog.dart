import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showPaymentPreviewDialog(
  BuildContext context,
  Map<String, dynamic> payment,
) {
  final rows = <({String label, String value})>[
    (label: 'Client', value: payment['rider_email']?.toString() ?? '—'),
    (
      label: 'Amount',
      value:
          '${payment['amount'] ?? '—'} ${payment['currency']?.toString() ?? ''}'.trim(),
    ),
    (label: 'Status', value: payment['status']?.toString() ?? '—'),
    (label: 'Provider', value: payment['provider']?.toString() ?? '—'),
    (
      label: 'Provider ref',
      value: payment['provider_intent_id']?.toString() ?? '—',
    ),
    (
      label: 'Trip',
      value: _shortId(payment['trip_id']?.toString()),
    ),
    (
      label: 'Request',
      value: _shortId(payment['request_id']?.toString()),
    ),
    (
      label: 'Created',
      value: _formatTimestamp(payment['created_at']?.toString()),
    ),
    (
      label: 'Settled',
      value: payment['settled_at'] != null
          ? _formatTimestamp(payment['settled_at']?.toString())
          : '—',
    ),
    (label: 'ID', value: payment['id']?.toString() ?? '—'),
  ];

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Payment details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _shortId(String? value) {
  if (value == null || value.isEmpty) return '—';
  return value.length <= 8 ? value.toUpperCase() : value.substring(0, 8).toUpperCase();
}

String _formatTimestamp(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return DateFormat.yMd().add_Hm().format(dt.toLocal());
}
