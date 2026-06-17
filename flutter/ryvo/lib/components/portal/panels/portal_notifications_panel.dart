import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalNotificationsPanel extends ConsumerStatefulWidget {
  const PortalNotificationsPanel({super.key});

  @override
  ConsumerState<PortalNotificationsPanel> createState() => _PortalNotificationsPanelState();
}

class _PortalNotificationsPanelState extends ConsumerState<PortalNotificationsPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

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
      final res = await notificationService.getInbox(auth.accessToken);
      if (!mounted) return;
      setState(() {
        _items = portalMapList(res, 'items');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.notifications.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _markRead(String id) async {
    final auth = useAuth(ref);
    try {
      await notificationService.markRead(auth.accessToken, id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    if (_items.isEmpty) return portalEmpty(T.nav('common.noData'));

    return AdminTableCard(
      child: AdminTable(
        child: DataTable(
          columns: [
            DataColumn(label: Text(T.portal('portal.notifications.columns.title'))),
            DataColumn(label: Text(T.portal('portal.notifications.columns.status'))),
            DataColumn(label: Text(T.portal('portal.notifications.columns.date'))),
            const DataColumn(label: SizedBox.shrink()),
          ],
          rows: _items.map((item) {
            final id = portalStr(item['id']);
            final isRead = item['read_at'] != null || item['is_read'] == true;
            return DataRow(
              cells: [
                DataCell(Text(portalStr(item['title'], portalStr(item['subject'])))),
                DataCell(
                  StatusBadge(
                    label: isRead ? T.portal('portal.notifications.read') : T.portal('portal.notifications.unread'),
                    variant: isRead ? StatusBadgeVariant.success : StatusBadgeVariant.warning,
                  ),
                ),
                DataCell(Text(formatLastSeen(portalStr(item['created_at'], '')))),
                DataCell(
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: isRead ? null : () => _markRead(id),
                    child: Text(T.portal('portal.notifications.markRead')),
                  ),
                ),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
