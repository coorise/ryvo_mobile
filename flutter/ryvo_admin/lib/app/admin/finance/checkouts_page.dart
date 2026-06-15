import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinanceCheckoutsPage extends ConsumerStatefulWidget {
  const FinanceCheckoutsPage({super.key});

  @override
  ConsumerState<FinanceCheckoutsPage> createState() =>
      _FinanceCheckoutsPageState();
}

class _FinanceCheckoutsPageState extends ConsumerState<FinanceCheckoutsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = useAuth(ref).accessToken;
    final json = await financeService.getCheckouts(token);
    final rows = (json['checkouts'] is List)
        ? (json['checkouts'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    return rows;
  }

  Future<void> _sendRecovery(String id) async {
    final token = useAuth(ref).accessToken;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await financeService.scheduleCheckoutRecovery(token, id, {
        'channel': 'email',
        'message': 'Please complete your pending checkout.',
      });
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Recovery reminder scheduled.')),
      );
      setState(() => _future = _load());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to schedule recovery: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const [
        'finances:checkouts:read',
        'finances:checkouts:update',
        'payments:read',
      ],
      fallback: const Center(
        child: Text('You do not have access to checkout recovery.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AdminListStack(
          children: [
            const AdminPageHeader(
              title: 'Checkouts Recovery',
              subtitle:
                  'Pending and failed checkouts with quick recovery reminders.',
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Failed to load checkouts: ${snapshot.error}');
                }
                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                return AdminTableCard(
                  isEmpty: rows.isEmpty,
                  empty: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No checkout records found.'),
                  ),
                  child: AdminTable(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Checkout')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: rows
                          .map((row) {
                            final id = row['id']?.toString() ?? '';
                            final status =
                                row['status']?.toString() ?? 'unknown';
                            return DataRow(
                              cells: [
                                DataCell(Text(id.isEmpty ? '—' : id)),
                                DataCell(
                                  Text(
                                    (row['user_id'] ?? row['email'] ?? '—')
                                        .toString(),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (row['amount'] ?? row['fare'] ?? '—')
                                        .toString(),
                                  ),
                                ),
                                DataCell(
                                  StatusBadge(
                                    label: status,
                                    variant: status == 'failed'
                                        ? StatusBadgeVariant.danger
                                        : StatusBadgeVariant.warning,
                                  ),
                                ),
                                DataCell(
                                  OutlinedButton(
                                    onPressed: (_sending || id.isEmpty)
                                        ? null
                                        : () => _sendRecovery(id),
                                    child: const Text('Recover'),
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
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
