import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinancePaychecksPage extends ConsumerStatefulWidget {
  const FinancePaychecksPage({super.key});

  @override
  ConsumerState<FinancePaychecksPage> createState() =>
      _FinancePaychecksPageState();
}

class _FinancePaychecksPageState extends ConsumerState<FinancePaychecksPage> {
  late Future<_PaychecksPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PaychecksPayload> _load() async {
    final token = useAuth(ref).accessToken;
    final paychecks = await financeService.getPaychecks(token);
    final earnings = await financeService.getDriverEarnings(token);
    return _PaychecksPayload(paychecks: paychecks, earnings: earnings);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:paychecks:read', 'payments:read'],
      fallback: const Center(
        child: Text('You do not have access to paychecks.'),
      ),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_PaychecksPayload>(
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
              if (snapshot.hasError || !snapshot.hasData) {
                return Text('Failed to load paychecks: ${snapshot.error}');
              }
              final data = snapshot.data!;
              return AdminListStack(
                children: [
                  const AdminPageHeader(
                    title: 'Paychecks',
                    subtitle: 'Paycheck queue and driver earnings snapshot.',
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Paying'),
                      Tab(text: 'Drivers Amount'),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        _RowsTab(
                          rows: data.paychecks['paychecks'],
                          emptyMessage: 'No paychecks available.',
                        ),
                        _RowsTab(
                          rows: data.earnings['earnings'],
                          emptyMessage: 'No driver earnings available.',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PaychecksPayload {
  const _PaychecksPayload({required this.paychecks, required this.earnings});

  final Map<String, dynamic> paychecks;
  final Map<String, dynamic> earnings;
}

class _RowsTab extends StatelessWidget {
  const _RowsTab({required this.rows, required this.emptyMessage});

  final dynamic rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final list = (rows is List)
        ? rows
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
        : <Map<String, dynamic>>[];
    return AdminTableCard(
      isEmpty: list.isEmpty,
      empty: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(emptyMessage),
      ),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final row = list[index];
          final status = row['status']?.toString() ?? 'pending';
          return ListTile(
            dense: true,
            title: Text((row['id'] ?? row['driver_id'] ?? 'item').toString()),
            subtitle: Text(
              row.entries
                  .take(4)
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' • '),
            ),
            trailing: StatusBadge(
              label: status,
              variant: status == 'paid'
                  ? StatusBadgeVariant.success
                  : StatusBadgeVariant.warning,
            ),
          );
        },
      ),
    );
  }
}
