import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminPaymentsPage extends ConsumerStatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  ConsumerState<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends ConsumerState<AdminPaymentsPage> {
  Future<Map<String, dynamic>>? _future;
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    final status = _status == 'all' ? null : _status;
    return adminService.listPayments(
      useAuth(ref).accessToken,
      status: status,
      limit: 200,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['payments:read'],
      fallback: const Center(child: Text('No access to payments.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Payments',
              subtitle: 'Payments list from admin API.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminSearchToolbar(
              value: '',
              onChanged: (_) {},
              placeholder: 'Filter by status',
              filters: [
                AdminFilterSelect(
                  value: _status,
                  onChanged: (v) => setState(() {
                    _status = v;
                    _future = _load();
                  }),
                  options: const [
                    AdminFilterOption(value: 'all', label: 'All'),
                    AdminFilterOption(value: 'succeeded', label: 'Succeeded'),
                    AdminFilterOption(value: 'pending', label: 'Pending'),
                    AdminFilterOption(value: 'failed', label: 'Failed'),
                    AdminFilterOption(value: 'refunded', label: 'Refunded'),
                  ],
                ),
              ],
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AdminTableCard(
                    isEmpty: true,
                    empty: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Failed to load payments: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final raw = snapshot.data?['payments'];
                final rows = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];

                return AdminTableCard(
                  isEmpty: rows.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No payments found.'),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = rows[index];
                      final status = p['status']?.toString() ?? 'unknown';
                      final amount = p['amount'];
                      final currency = p['currency']?.toString() ?? '';
                      return ListTile(
                        title: Text('$amount $currency'),
                        subtitle: Text(
                          'Provider: ${p['provider'] ?? '—'} · Rider: ${p['rider_email'] ?? '—'}',
                        ),
                        trailing: StatusBadge(
                          label: status,
                          variant: status == 'succeeded'
                              ? StatusBadgeVariant.success
                              : status == 'pending'
                              ? StatusBadgeVariant.warning
                              : status == 'failed'
                              ? StatusBadgeVariant.danger
                              : StatusBadgeVariant.defaultVariant,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
