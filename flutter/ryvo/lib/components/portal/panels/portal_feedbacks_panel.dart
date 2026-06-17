import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalFeedbacksPanel extends ConsumerStatefulWidget {
  const PortalFeedbacksPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalFeedbacksPanel> createState() => _PortalFeedbacksPanelState();
}

class _PortalFeedbacksPanelState extends ConsumerState<PortalFeedbacksPanel> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = useAuth(ref);
    setState(() {
      _loading = true;
      _error = null;
    });
    final category = widget.area == PortalArea.driver ? 'driver' : 'product';
    try {
      final res = await feedbacksService.getAnalytics(auth.accessToken, category, 'day');
      if (!mounted) return;
      setState(() {
        _analytics = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.feedbacks.unavailable');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    final summary = _analytics?['summary'];
    final series = portalMapList(_analytics, 'series');
    final average = summary is Map ? portalStr(summary['average'], '0') : '0';
    final total = summary is Map ? portalStr(summary['count'], '${series.length}') : '${series.length}';
    final positive = summary is Map ? portalStr(summary['positive_rate'], '0') : '0';

    return AdminListStack(
      children: [
        AdminCollapsibleOverview(
          title: T.portal('portal.nav.overview'),
          summary: '$average avg · $total ${T.portal('portal.feedbacks.stats.total').toLowerCase()} · $positive%',
          child: AdminStatGrid(
            children: [
              AdminStatCard(
                label: T.portal('portal.feedbacks.stats.average'),
                value: average,
                icon: LucideIcons.star,
                tone: AdminStatTone.warning,
              ),
              AdminStatCard(
                label: T.portal('portal.feedbacks.stats.total'),
                value: total,
                icon: LucideIcons.messageCircle,
              ),
              AdminStatCard(
                label: T.portal('portal.feedbacks.stats.positiveRate'),
                value: '$positive%',
                icon: LucideIcons.thumbsUp,
                tone: AdminStatTone.success,
              ),
            ],
          ),
        ),
        AdminTableCard(
          child: AdminTable(
            child: DataTable(
              columns: [
                DataColumn(label: Text(T.portal('portal.feedbacks.columns.period'))),
                DataColumn(label: Text(T.portal('portal.feedbacks.columns.average'))),
                DataColumn(label: Text(T.portal('portal.feedbacks.columns.count'))),
              ],
              rows: series.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(portalStr(row['period'], portalStr(row['date'])))),
                    DataCell(Text(portalStr(row['average'], '0'))),
                    DataCell(Text(portalStr(row['count'], '0'))),
                  ],
                );
              }).toList(growable: false),
            ),
          ),
          isEmpty: series.isEmpty,
          empty: portalEmpty(T.nav('common.noData')),
        ),
      ],
    );
  }
}
