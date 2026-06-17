import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalAnalyticsPanel extends ConsumerStatefulWidget {
  const PortalAnalyticsPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalAnalyticsPanel> createState() => _PortalAnalyticsPanelState();
}

class _PortalAnalyticsPanelState extends ConsumerState<PortalAnalyticsPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = useAuth(ref);
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await portalService.listMyTrips(auth.accessToken, limit: 500);
      if (!mounted) return;
      setState(() {
        _trips = portalMapList(res, 'trips');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.analytics.unavailable');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    if (_trips.isEmpty) return portalEmpty(T.nav('common.noData'));

    final completed = _trips.where((t) => portalStr(t['status']) == 'completed').length;
    final cancelled = _trips
        .where((t) => portalStr(t['status']) == 'cancelled' || portalStr(t['status']) == 'canceled')
        .length;
    final inProgress = _trips
        .where((t) => portalStr(t['status']) == 'in_progress' || portalStr(t['status']) == 'active')
        .length;
    final revenue = _trips.fold<num>(0, (sum, trip) {
      final fare = trip['fare_amount'];
      if (fare is num) return sum + fare;
      final parsed = num.tryParse(portalStr(fare, '0')) ?? 0;
      return sum + parsed;
    });

    return AdminListStack(
      children: [
        AdminCollapsibleOverview(
          title: T.portal('portal.nav.overview'),
          summary:
              '${_trips.length} ${T.portal('portal.analytics.totalTrips').toLowerCase()} · $completed ${T.portal('portal.analytics.completed').toLowerCase()} · ${formatMoney(revenue)}',
          child: AdminStatGrid(
            children: [
              AdminStatCard(
                label: T.portal('portal.analytics.totalTrips'),
                value: '${_trips.length}',
                icon: LucideIcons.barChart3,
              ),
              AdminStatCard(
                label: T.portal('portal.analytics.completed'),
                value: '$completed',
                icon: LucideIcons.circleCheck,
                tone: AdminStatTone.success,
              ),
              AdminStatCard(
                label: T.portal('portal.analytics.cancelled'),
                value: '$cancelled',
                icon: LucideIcons.circleX,
                tone: AdminStatTone.danger,
              ),
              AdminStatCard(
                label: T.portal('portal.analytics.revenue'),
                value: formatMoney(revenue),
                icon: LucideIcons.wallet,
                tone: AdminStatTone.info,
              ),
            ],
          ),
        ),
        AdminTableCard(
          child: AdminTable(
            child: DataTable(
              columns: [
                DataColumn(label: Text(T.portal('portal.analytics.columns.period'))),
                DataColumn(label: Text(T.portal('portal.analytics.columns.trips'))),
                DataColumn(label: Text(T.portal('portal.analytics.columns.completed'))),
                DataColumn(label: Text(T.portal('portal.analytics.columns.cancelled'))),
              ],
              rows: _byMonthRows(),
            ),
          ),
        ),
        Text(
          widget.area == PortalArea.driver ? 'Driver analytics' : 'Client analytics',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '${T.portal('portal.analytics.inProgress')}: $inProgress',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<DataRow> _byMonthRows() {
    final buckets = <String, List<Map<String, dynamic>>>{};
    for (final trip in _trips) {
      final createdAt = portalStr(trip['created_at'], '');
      final month = createdAt.length >= 7 ? createdAt.substring(0, 7) : 'unknown';
      buckets.putIfAbsent(month, () => <Map<String, dynamic>>[]).add(trip);
    }
    final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys.map((month) {
      final items = buckets[month]!;
      final completed = items.where((t) => portalStr(t['status']) == 'completed').length;
      final cancelled = items
          .where((t) => portalStr(t['status']) == 'cancelled' || portalStr(t['status']) == 'canceled')
          .length;
      return DataRow(
        cells: [
          DataCell(Text(month)),
          DataCell(Text('${items.length}')),
          DataCell(Text('$completed')),
          DataCell(Text('$cancelled')),
        ],
      );
    }).toList(growable: false);
  }
}
