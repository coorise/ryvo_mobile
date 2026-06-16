import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinanceSpeculativePage extends ConsumerStatefulWidget {
  const FinanceSpeculativePage({super.key});

  @override
  ConsumerState<FinanceSpeculativePage> createState() =>
      _FinanceSpeculativePageState();
}

class _FinanceSpeculativePageState
    extends ConsumerState<FinanceSpeculativePage> {
  late Future<_SpeculativeSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SpeculativeSnapshot> _load() async {
    final token = useAuth(ref).accessToken;
    final paychecks = await financeService.getPaychecks(token);
    final checkouts = await financeService.getCheckouts(token);
    final tariffs = await financeService.getTariffs(token);

    final paycheckRows = _mapList(paychecks['paychecks']);
    final checkoutRows = _mapList(checkouts['checkouts']);
    final tariffRows = _mapList(tariffs['tariffs']);

    final collectedRevenue = _sumField(paycheckRows, const [
      'amount',
      'net_amount',
      'value',
    ]);
    final pendingRevenue = _sumField(checkoutRows, const [
      'amount',
      'fare',
      'total',
    ]);
    final monthlyTariffBase = _sumField(tariffRows, const [
      'price',
      'monthly_price',
      'amount',
    ]);
    final opexEstimate = (collectedRevenue * 0.58) + (monthlyTariffBase * 0.25);

    return _SpeculativeSnapshot(
      collectedRevenue: collectedRevenue,
      pendingRevenue: pendingRevenue,
      monthlyTariffBase: monthlyTariffBase,
      opexEstimate: opexEstimate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:speculative:read', 'payments:read'],
      fallback: const Center(
        child: Text('You do not have access to speculative estimator.'),
      ),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_SpeculativeSnapshot>(
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
                return Text(
                  'Failed to build estimator snapshot: ${snapshot.error}',
                );
              }
              final data = snapshot.data!;
              return AdminListStack(
                children: [
                  const AdminPageHeader(
                    title: 'Speculative Estimator',
                    subtitle: 'Simplified revenue versus opex estimator.',
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Revenue'),
                      Tab(text: 'Opex'),
                    ],
                  ),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      children: [
                        _EstimatorCards(
                          cards: [
                            _EstimatorCardData(
                              'Collected Revenue',
                              data.collectedRevenue,
                              AdminStatTone.success,
                            ),
                            _EstimatorCardData(
                              'Pending Revenue',
                              data.pendingRevenue,
                              AdminStatTone.info,
                            ),
                            _EstimatorCardData(
                              'Tariff Base',
                              data.monthlyTariffBase,
                              AdminStatTone.neutral,
                            ),
                          ],
                        ),
                        _EstimatorCards(
                          cards: [
                            _EstimatorCardData(
                              'Estimated Opex',
                              data.opexEstimate,
                              AdminStatTone.warning,
                            ),
                            _EstimatorCardData(
                              'Projected Margin',
                              data.collectedRevenue - data.opexEstimate,
                              AdminStatTone.success,
                            ),
                          ],
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

class _SpeculativeSnapshot {
  const _SpeculativeSnapshot({
    required this.collectedRevenue,
    required this.pendingRevenue,
    required this.monthlyTariffBase,
    required this.opexEstimate,
  });

  final double collectedRevenue;
  final double pendingRevenue;
  final double monthlyTariffBase;
  final double opexEstimate;
}

class _EstimatorCardData {
  const _EstimatorCardData(this.label, this.value, this.tone);

  final String label;
  final double value;
  final AdminStatTone tone;
}

class _EstimatorCards extends StatelessWidget {
  const _EstimatorCards({required this.cards});

  final List<_EstimatorCardData> cards;

  @override
  Widget build(BuildContext context) {
    return AdminStatGrid(
      children: cards
          .map(
            (c) => AdminStatCard(
              label: c.label,
              value: c.value.toStringAsFixed(2),
              icon: Icons.query_stats_outlined,
              tone: c.tone,
            ),
          )
          .toList(growable: false),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

double _sumField(List<Map<String, dynamic>> rows, List<String> candidateKeys) {
  var sum = 0.0;
  for (final row in rows) {
    dynamic value;
    for (final key in candidateKeys) {
      if (row.containsKey(key)) {
        value = row[key];
        break;
      }
    }
    if (value == null) continue;
    if (value is num) {
      sum += value.toDouble();
    } else {
      sum += double.tryParse(value.toString()) ?? 0;
    }
  }
  return sum;
}
