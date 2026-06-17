import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalCounterpartiesPanel extends ConsumerStatefulWidget {
  const PortalCounterpartiesPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalCounterpartiesPanel> createState() => _PortalCounterpartiesPanelState();
}

class _PortalCounterpartiesPanelState extends ConsumerState<PortalCounterpartiesPanel>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];
  String? _selectedId;
  bool _profileLoading = false;
  Map<String, dynamic>? _profile;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = useAuth(ref);
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await portalService.listMyTrips(auth.accessToken, limit: 300);
      final trips = portalMapList(res, 'trips');
      final map = <String, Map<String, dynamic>>{};
      for (final trip in trips) {
        final otherId = widget.area == PortalArea.driver
            ? portalStr(trip['client_id'], '')
            : portalStr(trip['driver_id'], '');
        if (otherId.isEmpty) continue;
        final prev = map[otherId];
        map[otherId] = {
          'id': otherId,
          'trips': (prev?['trips'] as int? ?? 0) + 1,
          'latest_status': portalStr(trip['status']),
        };
      }
      final rows = map.values.toList(growable: false)
        ..sort((a, b) => (b['trips'] as int).compareTo(a['trips'] as int));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.counterparties.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _openProfile(String id) async {
    final auth = useAuth(ref);
    setState(() {
      _selectedId = id;
      _profile = null;
      _profileLoading = true;
    });
    try {
      final res = await profileService.getDriverPublicProfile(auth.accessToken, id);
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(res);
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
      });
    }
    _tabController?.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.area == PortalArea.driver ? T.portal('portal.nav.clients') : T.portal('portal.nav.drivers');
    return AdminListStack(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        AdminMobileColumnTabs(
          tabController: _tabController,
          scrollableOnMobile: true,
          tabHeight: 360,
          tabs: [
            T.portal('portal.counterparties.tabs.list'),
            T.portal('portal.counterparties.tabs.profile'),
          ],
          children: [
            _loading
                ? portalLoading()
                : _error != null
                    ? portalError(_error!)
                    : AdminTableCard(
                        child: AdminTable(
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(T.portal('portal.counterparties.columns.user'))),
                              DataColumn(label: Text(T.portal('portal.counterparties.columns.trips'))),
                              DataColumn(label: Text(T.portal('portal.counterparties.columns.status'))),
                              const DataColumn(label: SizedBox.shrink()),
                            ],
                            rows: _rows.map((row) {
                              final id = portalStr(row['id']);
                              final trips = row['trips'] as int? ?? 0;
                              final status = portalStr(row['latest_status'], 'unknown');
                              return DataRow(
                                cells: [
                                  DataCell(Text(id)),
                                  DataCell(Text('$trips')),
                                  DataCell(StatusBadge(label: status, variant: portalTripStatus(status))),
                                  DataCell(
                                    ShadButton.outline(
                                      size: ShadButtonSize.sm,
                                      onPressed: widget.area == PortalArea.client ? () => _openProfile(id) : null,
                                      child: Text(T.portal('portal.counterparties.viewProfile')),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(growable: false),
                          ),
                        ),
                        isEmpty: _rows.isEmpty,
                        empty: portalEmpty(T.nav('common.noData')),
                      ),
            _selectedId == null
                ? portalEmpty(T.portal('portal.counterparties.selectProfile'))
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _profileLoading
                          ? portalLoading()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.userRound),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        portalStr(_profile?['profile']?['full_name'], _selectedId!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => _selectedId = null),
                                      icon: const Icon(LucideIcons.x),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${T.portal('portal.counterparties.trips')}: ${portalStr(_profile?['profile']?['trip_count'], '0')}',
                                ),
                              ],
                            ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
