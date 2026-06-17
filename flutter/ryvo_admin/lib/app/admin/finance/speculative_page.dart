import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_admin_dashboard.dart';
import 'package:ryvo_admin/lib/csv_export.dart';
import 'package:ryvo_admin/lib/finance_speculative.dart';
import 'package:ryvo_admin/stores/opex_config_store.dart';

class FinanceSpeculativePage extends ConsumerStatefulWidget {
  const FinanceSpeculativePage({super.key});

  @override
  ConsumerState<FinanceSpeculativePage> createState() =>
      _FinanceSpeculativePageState();
}

class _FinanceSpeculativePageState extends ConsumerState<FinanceSpeculativePage> {
  PeriodFilter _period = PeriodFilter.monthly;

  @override
  Widget build(BuildContext context) {
    final resources = ref.watch(opexConfigProvider);
    final dashboard = ref.watch(adminDashboardProvider).valueOrNull;
    final baseRevenue = [
      ((dashboard?.stats['revenue_today'] as num?)?.toDouble() ?? 1200) * 30,
      28000.0,
    ].reduce((a, b) => a > b ? a : b);
    final trend = buildFinanceTrend(_period, resources, baseRevenue, 20);
    var totalRev = 0.0;
    var totalOpex = 0.0;
    for (final p in trend) {
      totalRev += p.revenue;
      totalOpex += p.opex;
    }
    final monthly = monthlyOpex(resources);
    final roi = roiPercent(totalRev, totalOpex);
    final chartRows = trend.map((p) => p.toChartRow()).toList(growable: false);

    return PermissionGate(
      permissions: const ['finances:speculative:read', 'payments:read'],
      fallback: const Center(child: Text('You do not have access to speculative estimator.')),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AdminListStack(
            children: [
              AdminPageHeader(
                title: 'Speculative Estimator',
                subtitle: 'Revenue trends and configurable OPEX resources.',
                action: OutlinedButton.icon(
                  onPressed: () {
                    final body = StringBuffer('Ryvo Speculative Export ($_period)\n\n')
                      ..writeln('Total revenue,${totalRev.toStringAsFixed(0)}')
                      ..writeln('Total opex,${totalOpex.toStringAsFixed(0)}')
                      ..writeln('ROI,$roi%')
                      ..writeln('OPEX band,${monthly.low.toStringAsFixed(0)}-${monthly.high.toStringAsFixed(0)}/mo')
                      ..writeln('\nPeriod,Revenue,Opex,Profit');
                    for (final p in trend) {
                      body.writeln('${p.label},${p.revenue},${p.opex},${p.profit}');
                    }
                    showTextExportDialog(context, title: 'Export summary', body: body.toString());
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export'),
                ),
              ),
              Wrap(
                spacing: 8,
                children: PeriodFilter.values.map((p) {
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: _period == p,
                    onSelected: (_) => setState(() => _period = p),
                  );
                }).toList(growable: false),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Revenue'),
                  Tab(text: 'Opex'),
                ],
              ),
              SizedBox(
                height: 560,
                child: TabBarView(
                  children: [
                    AdminListStack(
                      children: [
                        AdminCollapsibleOverview(
                          summary:
                              '\$${totalRev.toStringAsFixed(0)} revenue · \$${totalOpex.toStringAsFixed(0)} opex · $roi% ROI',
                          child: AdminStatGrid(
                            children: [
                              AdminStatCard(
                                label: 'Total Revenue',
                                value: '\$${totalRev.toStringAsFixed(0)}',
                                icon: Icons.trending_up,
                                tone: AdminStatTone.success,
                              ),
                              AdminStatCard(
                                label: 'Total Opex',
                                value: '\$${totalOpex.toStringAsFixed(0)}',
                                icon: Icons.payments_outlined,
                                tone: AdminStatTone.warning,
                              ),
                              AdminStatCard(
                                label: 'ROI',
                                value: '$roi%',
                                icon: Icons.query_stats,
                                tone: AdminStatTone.info,
                              ),
                            ],
                          ),
                        ),
                        AdminTableCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revenue vs Opex',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 12),
                                _DualBars(rows: chartRows),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    _OpexTab(resources: resources),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DualBars extends StatelessWidget {
  const _DualBars({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No trend data');
    final maxVal = rows.fold<double>(1, (max, row) {
      final rev = (row['revenue'] as num?)?.toDouble() ?? 0;
      final opex = (row['opex'] as num?)?.toDouble() ?? 0;
      return [max, rev, opex].reduce((a, b) => a > b ? a : b);
    });
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rows.map((row) {
          final label = row['label']?.toString() ?? '';
          final rev = (row['revenue'] as num?)?.toDouble() ?? 0;
          final opex = (row['opex'] as num?)?.toDouble() ?? 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            height: (160 * (rev / maxVal)).clamp(6, 160),
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            height: (160 * (opex / maxVal)).clamp(6, 160),
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _OpexTab extends ConsumerWidget {
  const _OpexTab({required this.resources});

  final List<OpexResource> resources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = monthlyOpex(resources);
    return AdminListStack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly OPEX estimate', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '\$${monthly.low.toStringAsFixed(0)} – \$${monthly.high.toStringAsFixed(0)} / mo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddResourceSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add resource'),
                ),
              ],
            ),
          ),
        ),
        ...resources.map((r) {
          final band = opexHourlyBand(r);
          return Card(
            child: ListTile(
              title: Text(r.provider),
              subtitle: Text(
                '${r.cpus} CPU · ${r.ramGb} GB RAM · ${r.storageGb} GB · '
                '\$${band.low.toStringAsFixed(3)}–\$${band.high.toStringAsFixed(3)}/hr',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(opexConfigProvider.notifier).removeResource(r.id),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAddResourceSheet(BuildContext context, WidgetRef ref) async {
    final providerCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0.10');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add OPEX resource', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: providerCtrl,
              decoration: const InputDecoration(labelText: 'Provider', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price / hour', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final name = providerCtrl.text.trim();
                if (name.isEmpty) return;
                await ref.read(opexConfigProvider.notifier).addResource(
                      OpexResource(
                        id: 'res-${DateTime.now().millisecondsSinceEpoch}',
                        provider: name,
                        cpus: 2,
                        ramGb: 4,
                        storageGb: 50,
                        bandwidthMode: BandwidthMode.metered,
                        bandwidthGb: 100,
                        pricePerHour: double.tryParse(priceCtrl.text.trim()) ?? 0.1,
                        marginDown: -0.1,
                        marginUp: 0.15,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save resource'),
            ),
          ],
        ),
      ),
    );
  }
}
