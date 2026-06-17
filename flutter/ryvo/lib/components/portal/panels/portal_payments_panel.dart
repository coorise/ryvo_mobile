import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalPaymentsPanel extends ConsumerStatefulWidget {
  const PortalPaymentsPanel({super.key});

  @override
  ConsumerState<PortalPaymentsPanel> createState() => _PortalPaymentsPanelState();
}

class _PortalPaymentsPanelState extends ConsumerState<PortalPaymentsPanel> {
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  String _search = '';
  List<Map<String, dynamic>> _payments = const [];

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
      final res = await portalService.listMyPayments(
        auth.accessToken,
        status: _statusFilter,
        limit: 500,
      );
      if (!mounted) return;
      setState(() {
        _payments = portalMapList(res, 'payments');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.payments.unavailable');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _payments.where((payment) {
      final text = '${portalStr(payment['id'])} ${portalStr(payment['status'])} ${portalStr(payment['currency'])}'
          .toLowerCase();
      return text.contains(_search.toLowerCase());
    }).toList(growable: false);

    final succeeded = filtered.where((p) => portalStr(p['status']) == 'succeeded').toList(growable: false);
    final pendingCount = filtered
        .where((p) => portalStr(p['status']) == 'pending' || portalStr(p['status']) == 'processing')
        .length;
    final volume = succeeded.fold<num>(0, (sum, p) {
      final amount = p['amount'];
      if (amount is num) return sum + amount;
      return sum + (num.tryParse(portalStr(amount, '0')) ?? 0);
    });

    return AdminListStack(
      children: [
        AdminStatGrid(
          children: [
            AdminStatCard(
              label: T.portal('portal.payments.stats.total'),
              value: '${filtered.length}',
              icon: LucideIcons.banknote,
            ),
            AdminStatCard(
              label: T.portal('portal.payments.stats.volume'),
              value: formatMoney(volume),
              icon: LucideIcons.circleCheck,
              tone: AdminStatTone.success,
            ),
            AdminStatCard(
              label: T.portal('portal.payments.stats.pending'),
              value: '$pendingCount',
              icon: LucideIcons.clock3,
              tone: AdminStatTone.warning,
            ),
          ],
        ),
        AdminSearchToolbar(
          value: _search,
          onChanged: (value) => setState(() => _search = value),
          placeholder: T.portal('portal.payments.searchPlaceholder'),
          filters: [
            AdminFilterSelect(
              value: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                _load();
              },
              options: [
                AdminFilterOption(value: 'all', label: T.portal('portal.payments.filters.all')),
                AdminFilterOption(
                  value: 'succeeded',
                  label: T.portal('portal.payments.filters.succeeded'),
                ),
                AdminFilterOption(value: 'pending', label: T.portal('portal.payments.filters.pending')),
                AdminFilterOption(value: 'failed', label: T.portal('portal.payments.filters.failed')),
              ],
            ),
          ],
        ),
        if (_loading)
          portalLoading()
        else if (_error != null)
          portalError(_error!)
        else
          AdminTableCard(
            child: AdminTable(
              child: DataTable(
                columns: [
                  DataColumn(label: Text(T.portal('portal.payments.columns.date'))),
                  DataColumn(label: Text(T.portal('portal.payments.columns.amount'))),
                  DataColumn(label: Text(T.portal('portal.payments.columns.status'))),
                  DataColumn(label: Text(T.portal('portal.payments.columns.id'))),
                ],
                rows: filtered.map((payment) {
                  final amount = payment['amount'];
                  final currency = portalStr(payment['currency'], 'USD');
                  final amountNum = amount is num ? amount : (num.tryParse(portalStr(amount, '0')) ?? 0);
                  final status = portalStr(payment['status'], 'unknown');
                  return DataRow(
                    cells: [
                      DataCell(Text(formatLastSeen(portalStr(payment['created_at'], '')))),
                      DataCell(Text(formatMoney(amountNum, currency: currency.toUpperCase()))),
                      DataCell(StatusBadge(label: status, variant: portalPaymentStatus(status))),
                      DataCell(Text(portalStr(payment['id']))),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
            isEmpty: filtered.isEmpty,
            empty: portalEmpty(T.nav('common.noData')),
          ),
      ],
    );
  }
}
