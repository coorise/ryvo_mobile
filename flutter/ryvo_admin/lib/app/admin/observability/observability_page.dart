import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class _ObservabilityMetric {
  const _ObservabilityMetric({
    required this.label,
    required this.used,
    required this.limit,
    required this.pct,
    required this.icon,
    this.tone = AdminStatTone.neutral,
  });

  final String label;
  final String used;
  final String limit;
  final int pct;
  final IconData icon;
  final AdminStatTone tone;
}

const _metrics = [
  _ObservabilityMetric(
    label: 'Database',
    used: '2.4 GB',
    limit: '8 GB',
    pct: 30,
    icon: Icons.storage,
    tone: AdminStatTone.info,
  ),
  _ObservabilityMetric(
    label: 'Storage',
    used: '12.1 GB',
    limit: '50 GB',
    pct: 24,
    icon: Icons.folder_open,
    tone: AdminStatTone.neutral,
  ),
  _ObservabilityMetric(
    label: 'API Traffic',
    used: '1.2M',
    limit: '5M req/mo',
    pct: 24,
    icon: Icons.network_check,
    tone: AdminStatTone.success,
  ),
  _ObservabilityMetric(
    label: 'MAU',
    used: '8,420',
    limit: '25,000',
    pct: 34,
    icon: Icons.people_alt_outlined,
    tone: AdminStatTone.warning,
  ),
];

class AdminObservabilityPage extends ConsumerStatefulWidget {
  const AdminObservabilityPage({super.key});

  @override
  ConsumerState<AdminObservabilityPage> createState() =>
      _AdminObservabilityPageState();
}

class _AdminObservabilityPageState
    extends ConsumerState<AdminObservabilityPage> {
  Future<Map<String, dynamic>>? _generalFuture;
  Future<Map<String, dynamic>>? _paymentFuture;

  @override
  void initState() {
    super.initState();
    final token = ref.read(authProvider).accessToken;
    _generalFuture = adminService.getSettings(token);
    _paymentFuture = settingsService.getPayment(token);
  }

  Future<void> _refresh() async {
    final token = ref.read(authProvider).accessToken;
    setState(() {
      _generalFuture = adminService.getSettings(token);
      _paymentFuture = settingsService.getPayment(token);
    });
    await Future.wait([_generalFuture!, _paymentFuture!]);
  }

  Color _progressColor(BuildContext context, int pct) {
    if (pct > 85) return Theme.of(context).colorScheme.error;
    if (pct > 70) return Colors.amber.shade600;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['observability:read', 'settings:read'],
      fallback: const Center(child: Text('No access to observability.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Observability',
              subtitle: 'Platform metrics and runtime health snapshot.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminCollapsibleOverview(
              summary: 'Database 30% · Storage 24% · API 24% · MAU 34%',
              child: AdminStatGrid(
                children: _metrics
                    .map(
                      (m) => _MetricCard(
                        metric: m,
                        progressColor: _progressColor(context, m.pct),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            AdminMobileColumnTabs(
              tabHeight: 220,
              tabs: const ['Runtime', 'Platform'],
              children: [
                AdminTableCard(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Runtime',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text('CPU: 42% (4 cores)'),
                        Text('RAM: 3.1 / 8 GB'),
                        Text('Functions: ryvo-functions · healthy'),
                      ],
                    ),
                  ),
                ),
                AdminTableCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Future.wait([_generalFuture!, _paymentFuture!]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Failed to load platform details: ${snapshot.error}',
                          );
                        }
                        final general = snapshot.data![0];
                        final payment = snapshot.data![1];
                        final prefs = general['preferences'] is Map
                            ? Map<String, dynamic>.from(
                                general['preferences'] as Map,
                              )
                            : <String, dynamic>{};
                        final config = payment['config'] is Map
                            ? Map<String, dynamic>.from(payment['config'] as Map)
                            : <String, dynamic>{};

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Platform',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text('App Name: ${prefs['appName'] ?? '—'}'),
                            Text(
                              'Default Language: ${prefs['defaultLanguage'] ?? '—'}',
                            ),
                            Text('Currency: ${config['currency'] ?? '—'}'),
                            const SizedBox(height: 8),
                            Text(
                              'Static metrics are shown until admin/platform endpoint is available.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.progressColor,
  });

  final _ObservabilityMetric metric;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _toneColors(context, metric.tone);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metric.icon, color: fgColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${metric.used} / ${metric.limit}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metric.pct / 100,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${metric.pct}% used',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

(Color, Color) _toneColors(BuildContext context, AdminStatTone tone) {
  final scheme = Theme.of(context).colorScheme;
  switch (tone) {
    case AdminStatTone.success:
      return (scheme.primaryContainer, scheme.primary);
    case AdminStatTone.warning:
      return (Colors.amber.withValues(alpha: 0.15), Colors.amber.shade800);
    case AdminStatTone.danger:
      return (scheme.errorContainer, scheme.error);
    case AdminStatTone.info:
      return (scheme.secondaryContainer, scheme.secondary);
    case AdminStatTone.neutral:
      return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
  }
}
