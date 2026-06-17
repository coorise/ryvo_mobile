import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_admin_dashboard.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGate(
      permissions: const [],
      child: ref
          .watch(adminDashboardProvider)
          .when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load dashboard: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            data: (data) {
              if (data == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No dashboard data'),
                  ),
                );
              }

              final stats = data.stats;
              final rides24h = (stats['rides_24h'] as num?)?.toInt() ?? 0;
              final revenueToday =
                  (stats['revenue_today'] as num?)?.toDouble() ?? 0;
              final cancelRate =
                  (stats['cancel_rate_pct'] as num?)?.toDouble() ?? 0;
              final satisfaction = stats['satisfaction_avg'] as num?;
              final chart = data.chart;
              final maxCount = chart.fold<num>(1, (max, e) {
                final count = (e['count'] as num?) ?? 0;
                return count > max ? count : max;
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'Dashboard',
                      subtitle:
                          'Realtime operations, risk alerts, and performance health.',
                    ),
                    const SizedBox(height: 16),
                    if (data.alerts.isNotEmpty) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: data.alerts
                            .map((alert) => _AlertCard(alert: alert))
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AdminCollapsibleOverview(
                      summary:
                          '$rides24h rides · ${NumberFormat.currency(symbol: r'$').format(revenueToday)} revenue · ${cancelRate.toStringAsFixed(1)}% cancel',
                      child: AdminStatGrid(
                        children: [
                          AdminStatCard(
                            icon: LucideIcons.car,
                            label: 'Rides (24h)',
                            value: NumberFormat.decimalPattern().format(rides24h),
                            tone: AdminStatTone.neutral,
                          ),
                          AdminStatCard(
                            icon: LucideIcons.dollarSign,
                            label: 'Revenue Today',
                            value: NumberFormat.currency(
                              symbol: r'$',
                            ).format(revenueToday),
                            tone: AdminStatTone.success,
                          ),
                          AdminStatCard(
                            icon: LucideIcons.xCircle,
                            label: 'Cancel Rate',
                            value: '${cancelRate.toStringAsFixed(1)}%',
                            tone: cancelRate > 5
                                ? AdminStatTone.danger
                                : AdminStatTone.warning,
                          ),
                          AdminStatCard(
                            icon: LucideIcons.star,
                            label: 'Satisfaction',
                            value: satisfaction == null
                                ? '—'
                                : '${satisfaction.toStringAsFixed(1)}/5',
                            tone: AdminStatTone.info,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1100;
                        final chartCard = _ChartCard(chart: chart, maxCount: maxCount);
                        final pendingCard =
                            _PendingDriversCard(drivers: data.pendingDrivers);
                        final auditCard = _RecentAuditCard(rows: data.recentAudit);
                        final liveCard = _LiveTripsCard(
                          activeTrips:
                              (data.live['active_trips'] as num?)?.toInt() ?? 0,
                        );

                        if (isWide) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth * 0.63,
                                child: chartCard,
                              ),
                              SizedBox(
                                width: constraints.maxWidth * 0.35,
                                child: pendingCard,
                              ),
                              SizedBox(
                                width: constraints.maxWidth * 0.63,
                                child: auditCard,
                              ),
                              SizedBox(
                                width: constraints.maxWidth * 0.35,
                                child: liveCard,
                              ),
                            ],
                          );
                        }

                        return DefaultTabController(
                          length: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: [
                                  Tab(text: 'Volume'),
                                  Tab(text: 'Pending'),
                                  Tab(text: 'Audit'),
                                  Tab(text: 'Live'),
                                ],
                              ),
                              SizedBox(
                                height: 320,
                                child: TabBarView(
                                  children: [
                                    chartCard,
                                    pendingCard,
                                    auditCard,
                                    liveCard,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final severity = (alert['severity'] ?? 'info').toString();
    final (bg, border, fg) = switch (severity) {
      'critical' => (
        Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        Theme.of(context).colorScheme.error.withValues(alpha: 0.45),
        Theme.of(context).colorScheme.error,
      ),
      'warning' => (
        const Color(0xFFF59E0B).withValues(alpha: 0.08),
        const Color(0xFFF59E0B).withValues(alpha: 0.5),
        const Color(0xFF92400E),
      ),
      _ => (
        const Color(0xFF0EA5E9).withValues(alpha: 0.08),
        const Color(0xFF0EA5E9).withValues(alpha: 0.4),
        const Color(0xFF0369A1),
      ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 450),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () {
              final href = alert['href']?.toString();
              if (href == null || href.isEmpty) return;
              context.go(href);
            },
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 18, color: fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['text']?.toString() ?? 'Alert',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(LucideIcons.arrowRight, size: 16, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.chart, required this.maxCount});

  final List<Map<String, dynamic>> chart;
  final num maxCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Rides per day', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (chart.isEmpty ||
                chart.every((e) => ((e['count'] as num?) ?? 0) <= 0))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No data')),
              )
            else
              SizedBox(
                height: 210,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chart
                      .map((row) {
                        final label = row['label']?.toString() ?? '—';
                        final count = (row['count'] as num?) ?? 0;
                        final ratio = (count / maxCount).clamp(0, 1).toDouble();
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
                                      width: double.infinity,
                                      height: (180 * ratio).clamp(8, 180),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(10),
                                            ),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.35),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
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
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingDriversCard extends StatelessWidget {
  const _PendingDriversCard({required this.drivers});

  final List<Map<String, dynamic>> drivers;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pending Drivers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(Routes.adminDriversList),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (drivers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No data'),
              )
            else
              ...drivers.take(6).map((d) {
                final name = d['name']?.toString() ?? 'Unknown';
                final city = d['city']?.toString() ?? '—';
                final id = d['id']?.toString() ?? '—';
                final status = d['status']?.toString() ?? 'pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$city · $id',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: status,
                        variant: StatusBadgeVariant.info,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RecentAuditCard extends StatelessWidget {
  const _RecentAuditCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Audit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(Routes.adminAudit),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('No data'),
              )
            else
              ...rows.take(8).map((e) {
                final createdAt = _formatShortTime(e['created_at']?.toString());
                final action = e['action']?.toString() ?? '—';
                final actor = e['actor_id']?.toString() ?? 'system';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          createdAt,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(actor, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _LiveTripsCard extends StatelessWidget {
  const _LiveTripsCard({required this.activeTrips});

  final int activeTrips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live - Montreal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.surface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.decimalPattern().format(activeTrips),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Active rides',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatShortTime(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return DateFormat.Hm().format(dt.toLocal());
}
