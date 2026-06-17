enum SupportAudience { clients, drivers }

SupportAudience ticketAudience(Map<String, dynamic> ticket) {
  final category = (ticket['category'] ?? '').toString().toLowerCase();
  if (category.contains('driver') ||
      category.contains('kyc') ||
      category.contains('chauffeur')) {
    return SupportAudience.drivers;
  }
  if (category.contains('client') ||
      category.contains('rider') ||
      category.contains('passenger')) {
    return SupportAudience.clients;
  }
  return SupportAudience.clients;
}

SupportAudience audienceFromSubTab(String? sub) {
  return sub == 'drivers' ? SupportAudience.drivers : SupportAudience.clients;
}

String ticketUserLabel(String userId) {
  final tail = userId.replaceAll('-', '');
  if (tail.length < 6) return 'User · $tail';
  return 'User · ${tail.substring(tail.length - 6)}';
}

String normTicketStatus(String status) {
  return status.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

int ticketSupportLevel(Map<String, dynamic> ticket) {
  final level = ticket['support_level'];
  if (level is num) {
    return level.clamp(1, 3).toInt();
  }
  return 1;
}

List<Map<String, dynamic>> filterSupportTickets(
  List<Map<String, dynamic>> tickets, {
  required SupportAudience audience,
  required String search,
  required String statusFilter,
  required String levelFilter,
}) {
  final q = search.trim().toLowerCase();
  final filtered = tickets.where((ticket) {
    if (ticketAudience(ticket) != audience) return false;
    final status = normTicketStatus(ticket['status']?.toString() ?? '');
    if (statusFilter != 'all' && status != statusFilter) return false;
    final level = ticketSupportLevel(ticket);
    if (levelFilter != 'all' && '$level' != levelFilter) return false;
    if (q.isEmpty) return true;
    final userId = ticket['user_id']?.toString() ?? '';
    return ticket['subject']?.toString().toLowerCase().contains(q) == true ||
        ticket['category']?.toString().toLowerCase().contains(q) == true ||
        ticket['id']?.toString().toLowerCase().contains(q) == true ||
        userId.toLowerCase().contains(q) ||
        ticketUserLabel(userId).toLowerCase().contains(q);
  }).toList(growable: false);

  const priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
  filtered.sort((a, b) {
    final pa = priorityOrder[a['priority']?.toString().toLowerCase()] ?? 9;
    final pb = priorityOrder[b['priority']?.toString().toLowerCase()] ?? 9;
    if (pa != pb) return pa.compareTo(pb);
    final la = ticketSupportLevel(a);
    final lb = ticketSupportLevel(b);
    if (lb != la) return lb.compareTo(la);
    final at = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bt = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  });
  return filtered;
}
