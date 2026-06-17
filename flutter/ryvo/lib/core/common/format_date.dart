import 'package:intl/intl.dart';

String formatLastSeen(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().add_jm().format(dt);
  } catch (_) {
    return iso;
  }
}

String formatMoney(num? amount, {String currency = 'USD'}) {
  if (amount == null) return '—';
  return NumberFormat.simpleCurrency(name: currency).format(amount);
}
