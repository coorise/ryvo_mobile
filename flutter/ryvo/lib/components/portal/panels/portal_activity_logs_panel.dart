import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalActivityLogsPanel extends ConsumerStatefulWidget {
  const PortalActivityLogsPanel({super.key});

  @override
  ConsumerState<PortalActivityLogsPanel> createState() => _PortalActivityLogsPanelState();
}

class _PortalActivityLogsPanelState extends ConsumerState<PortalActivityLogsPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _logs = const [];

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
    try {
      final res = await auditService.listMyActivityLogs(auth.accessToken, limit: 200);
      if (!mounted) return;
      setState(() {
        _logs = portalMapList(res, 'logs');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.activityLogs.unavailable');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    if (_logs.isEmpty) return portalEmpty(T.nav('common.noData'));

    return AdminTableCard(
      child: AdminTable(
        child: DataTable(
          columns: [
            DataColumn(label: Text(T.portal('portal.activityLogs.columns.action'))),
            DataColumn(label: Text(T.portal('portal.activityLogs.columns.resource'))),
            DataColumn(label: Text(T.portal('portal.activityLogs.columns.date'))),
          ],
          rows: _logs.map((log) {
            return DataRow(
              cells: [
                DataCell(Text(portalStr(log['action'], portalStr(log['event'], 'unknown')))),
                DataCell(Text(portalStr(log['resource'], portalStr(log['entity_type'])))),
                DataCell(Text(formatLastSeen(portalStr(log['created_at'], '')))),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
