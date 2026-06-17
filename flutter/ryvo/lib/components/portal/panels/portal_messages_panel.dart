import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalMessagesPanel extends ConsumerStatefulWidget {
  const PortalMessagesPanel({super.key});

  @override
  ConsumerState<PortalMessagesPanel> createState() => _PortalMessagesPanelState();
}

class _PortalMessagesPanelState extends ConsumerState<PortalMessagesPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _campaigns = const [];

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
      final res = await messagesService.list(auth.accessToken, audience: 'drivers');
      if (!mounted) return;
      setState(() {
        _campaigns = portalMapList(res, 'campaigns');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.messages.unavailable');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    if (_campaigns.isEmpty) return portalEmpty(T.nav('common.noData'));

    return AdminTableCard(
      child: AdminTable(
        child: DataTable(
          columns: [
            DataColumn(label: Text(T.portal('portal.messages.columns.subject'))),
            DataColumn(label: Text(T.portal('portal.messages.columns.status'))),
            DataColumn(label: Text(T.portal('portal.messages.columns.sent'))),
          ],
          rows: _campaigns.map((campaign) {
            final status = portalStr(campaign['status'], 'draft');
            return DataRow(
              cells: [
                DataCell(Text(portalStr(campaign['body_template'], portalStr(campaign['subject'])))),
                DataCell(StatusBadge(label: status)),
                DataCell(Text(formatLastSeen(portalStr(campaign['created_at'], '')))),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
