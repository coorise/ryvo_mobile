import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinanceTariffsPage extends ConsumerStatefulWidget {
  const FinanceTariffsPage({super.key});

  @override
  ConsumerState<FinanceTariffsPage> createState() => _FinanceTariffsPageState();
}

class _FinanceTariffsPageState extends ConsumerState<FinanceTariffsPage> {
  late Future<_TariffsPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TariffsPayload> _load() async {
    final token = useAuth(ref).accessToken;
    final tariffs = await financeService.getTariffs(token);
    final subscribers = await financeService.getTariffSubscriptions(token);
    return _TariffsPayload(tariffs: tariffs, subscribers: subscribers);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:tariffs:read', 'payments:read'],
      fallback: const Center(child: Text('You do not have access to tariffs.')),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_TariffsPayload>(
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
                return Text('Failed to load tariffs: ${snapshot.error}');
              }
              final data = snapshot.data!;
              return AdminListStack(
                children: [
                  const AdminPageHeader(
                    title: 'Tariffs',
                    subtitle: 'Tariff definitions and active subscriptions.',
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Tariffs'),
                      Tab(text: 'Subscribers'),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        _TableTab(
                          rows: data.tariffs['tariffs'],
                          emptyMessage: 'No tariffs found.',
                        ),
                        _TableTab(
                          rows: data.subscribers['subscriptions'],
                          emptyMessage: 'No subscribers found.',
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

class _TariffsPayload {
  const _TariffsPayload({required this.tariffs, required this.subscribers});

  final Map<String, dynamic> tariffs;
  final Map<String, dynamic> subscribers;
}

class _TableTab extends StatelessWidget {
  const _TableTab({required this.rows, required this.emptyMessage});

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
          return ListTile(
            dense: true,
            title: Text((row['name'] ?? row['id'] ?? 'Unnamed').toString()),
            subtitle: Text(
              row.entries
                  .take(4)
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' • '),
            ),
          );
        },
      ),
    );
  }
}
