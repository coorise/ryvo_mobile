import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/services/admin_service.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

typedef AnalyticsParams = ({String period, String audience});

final _analyticsProvider =
    FutureProvider.family<Map<String, dynamic>, AnalyticsParams>((
      ref,
      params,
    ) async {
      final auth = ref.watch(authProvider);
      final token = auth.accessToken;
      if (!auth.isReady || token == null || token.isEmpty) return const {};
      return adminService.getAnalytics(token, params.period, params.audience);
    });

class AdminAnalyticsPage extends ConsumerStatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  ConsumerState<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends ConsumerState<AdminAnalyticsPage> {
  String _period = '30d';
  String _audience = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      _analyticsProvider((period: _period, audience: _audience)),
    );

    return PermissionGate(
      permissions: const ['analytics:read', 'audit:read'],
      fallback: const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('No access')),
      ),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load analytics: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (data) {
          final kpis =
              (data['kpis'] as Map?)?.cast<String, dynamic>() ?? const {};
          final volume = _mapRows(data['volume']);
          final ratings = _mapRows(data['ratingDist']);
          final experience = _mapRows(data['experience']);
          final destinations = _mapRows(data['destinations']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminPageHeader(
                  title: 'Analytics',
                  subtitle: 'Trends, quality signals, and demand distribution.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...['7d', '30d', '90d', '1y'].map(
                      (period) => ChoiceChip(
                        label: Text(period),
                        selected: _period == period,
                        onSelected: (_) => setState(() => _period = period),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AdminFilterSelect(
                      width: 150,
                      value: _audience,
                      onChanged: (v) => setState(() => _audience = v),
                      options: const [
                        AdminFilterOption(value: 'all', label: 'All audiences'),
                        AdminFilterOption(value: 'clients', label: 'Clients'),
                        AdminFilterOption(value: 'drivers', label: 'Drivers'),
                      ],
                    ),
                    ShadButton.outline(
                      onPressed: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.download, size: 16),
                          SizedBox(width: 6),
                          Text('Export PDF'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AdminStatGrid(
                  children: [
                    AdminStatCard(
                      icon: LucideIcons.users,
                      label: 'Active Users',
                      value: NumberFormat.decimalPattern().format(
                        (kpis['activeUsers'] as num?)?.toInt() ?? 0,
                      ),
                    ),
                    AdminStatCard(
                      icon: LucideIcons.car,
                      label: 'Completed Trips',
                      value: NumberFormat.decimalPattern().format(
                        (kpis['completedTrips'] as num?)?.toInt() ?? 0,
                      ),
                    ),
                    AdminStatCard(
                      icon: LucideIcons.star,
                      label: 'Avg Rating',
                      value: ((kpis['avgRating'] as num?)?.toDouble() ?? 0)
                          .toStringAsFixed(2),
                      tone: AdminStatTone.success,
                    ),
                    AdminStatCard(
                      icon: LucideIcons.xCircle,
                      label: 'Cancel Rate',
                      value:
                          '${((kpis['cancelRate'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                      tone: AdminStatTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SimpleChartPanel(
                  title: 'Ride Volume',
                  subtitle: 'Trips over selected period',
                  child: _VerticalBars(
                    rows: volume,
                    valueKey: 'trips',
                    labelKey: 'label',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 980;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: wide
                              ? constraints.maxWidth * 0.49
                              : constraints.maxWidth,
                          child: _SimpleChartPanel(
                            title: 'Ratings Distribution',
                            child: _HorizontalBars(
                              rows: ratings,
                              valueKey: 'count',
                              labelBuilder: (row) => '${row['stars'] ?? '?'}★',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wide
                              ? constraints.maxWidth * 0.49
                              : constraints.maxWidth,
                          child: _SimpleChartPanel(
                            title: 'Experience',
                            child: _HorizontalBars(
                              rows: experience,
                              valueKey: 'score',
                              labelBuilder: (row) =>
                                  '${row['metric'] ?? 'Metric'}',
                              maxOverride: 5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SimpleChartPanel(
                  title: 'Top Destinations',
                  child: _DestinationsTable(rows: destinations),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimpleChartPanel extends StatelessWidget {
  const _SimpleChartPanel({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _VerticalBars extends StatelessWidget {
  const _VerticalBars({
    required this.rows,
    required this.valueKey,
    required this.labelKey,
    required this.color,
  });

  final List<Map<String, dynamic>> rows;
  final String valueKey;
  final String labelKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No data')),
      );
    }
    final maxValue = rows.fold<double>(1, (max, row) {
      final v = (row[valueKey] as num?)?.toDouble() ?? 0;
      return v > max ? v : max;
    });
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rows
            .map((row) {
              final label = row[labelKey]?.toString() ?? '—';
              final value = (row[valueKey] as num?)?.toDouble() ?? 0;
              final ratio = (value / maxValue).clamp(0, 1).toDouble();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: (170 * ratio).clamp(8, 170).toDouble(),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              color: color.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _HorizontalBars extends StatelessWidget {
  const _HorizontalBars({
    required this.rows,
    required this.valueKey,
    required this.labelBuilder,
    this.maxOverride,
  });

  final List<Map<String, dynamic>> rows;
  final String valueKey;
  final String Function(Map<String, dynamic>) labelBuilder;
  final double? maxOverride;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No data')),
      );
    }
    final maxValue =
        maxOverride ??
        rows.fold<double>(1, (max, row) {
          final v = (row[valueKey] as num?)?.toDouble() ?? 0;
          return v > max ? v : max;
        });
    return Column(
      children: rows
          .map((row) {
            final label = labelBuilder(row);
            final value = (row[valueKey] as num?)?.toDouble() ?? 0;
            final ratio = (value / maxValue).clamp(0, 1).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 42, child: Text(value.toStringAsFixed(1))),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _DestinationsTable extends StatelessWidget {
  const _DestinationsTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No data')),
      );
    }
    final total = rows.fold<int>(
      0,
      (sum, row) => sum + ((row['count'] as num?)?.toInt() ?? 0),
    );
    return Column(
      children: rows
          .map((row) {
            final name = row['name']?.toString() ?? '—';
            final count = (row['count'] as num?)?.toInt() ?? 0;
            final share = total == 0 ? 0 : ((count / total) * 100).round();
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 80, child: Text('$count')),
                  SizedBox(width: 70, child: Text('$share%')),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

List<Map<String, dynamic>> _mapRows(dynamic input) {
  if (input is! List) return const [];
  return input
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);
}
