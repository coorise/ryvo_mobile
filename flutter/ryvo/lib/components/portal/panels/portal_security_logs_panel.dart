import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalSecurityLogsPanel extends ConsumerStatefulWidget {
  const PortalSecurityLogsPanel({super.key});

  @override
  ConsumerState<PortalSecurityLogsPanel> createState() => _PortalSecurityLogsPanelState();
}

class _PortalSecurityLogsPanelState extends ConsumerState<PortalSecurityLogsPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = const [];
  List<Map<String, dynamic>> _devices = const [];

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
      final eventsRes = await auditService.listMySecurityAuthEvents(auth.accessToken);
      final devicesRes = await auditService.listMyDevices(auth.accessToken);
      if (!mounted) return;
      setState(() {
        _events = portalMapList(eventsRes, 'events');
        _devices = portalMapList(devicesRes, 'devices');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.securityLogs.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _revokeDevice(String id) async {
    final auth = useAuth(ref);
    try {
      await auditService.revokeMyDevice(auth.accessToken, id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    return AdminListStack(
      children: [
        AdminTableCard(
          child: AdminTable(
            child: DataTable(
              columns: [
                DataColumn(label: Text(T.portal('portal.securityLogs.columns.event'))),
                DataColumn(label: Text(T.portal('portal.securityLogs.columns.severity'))),
                DataColumn(label: Text(T.portal('portal.securityLogs.columns.date'))),
              ],
              rows: _events.isEmpty
                  ? const []
                  : _events.map((event) {
                      final severity = portalStr(event['severity'], 'info');
                      return DataRow(
                        cells: [
                          DataCell(Text(portalStr(event['event_type'], portalStr(event['type'])))),
                          DataCell(
                            StatusBadge(
                              label: severity,
                              variant: severity == 'high'
                                  ? StatusBadgeVariant.danger
                                  : (severity == 'medium'
                                      ? StatusBadgeVariant.warning
                                      : StatusBadgeVariant.info),
                            ),
                          ),
                          DataCell(Text(formatLastSeen(portalStr(event['created_at'], '')))),
                        ],
                      );
                    }).toList(growable: false),
            ),
          ),
          isEmpty: _events.isEmpty,
          empty: portalEmpty(T.nav('common.noData')),
        ),
        AdminTableCard(
          child: AdminTable(
            child: DataTable(
              columns: [
                DataColumn(label: Text(T.portal('portal.securityLogs.columns.device'))),
                DataColumn(label: Text(T.portal('portal.securityLogs.columns.lastSeen'))),
                const DataColumn(label: SizedBox.shrink()),
              ],
              rows: _devices.isEmpty
                  ? const []
                  : _devices.map((device) {
                      final id = portalStr(device['id']);
                      final revokedAt = portalStr(device['revoked_at'], '');
                      final revoked = revokedAt.isNotEmpty && revokedAt != '—';
                      return DataRow(
                        cells: [
                          DataCell(Text(portalStr(device['label'], portalStr(device['device_name'])))),
                          DataCell(Text(formatLastSeen(portalStr(device['last_seen_at'], '')))),
                          DataCell(
                            ShadButton.outline(
                              size: ShadButtonSize.sm,
                              onPressed: revoked ? null : () => _revokeDevice(id),
                              child: Text(T.portal('portal.securityLogs.revokeDevice')),
                            ),
                          ),
                        ],
                      );
                    }).toList(growable: false),
            ),
          ),
          isEmpty: _devices.isEmpty,
          empty: portalEmpty(T.nav('common.noData')),
        ),
      ],
    );
  }
}
