import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalRidesPanel extends ConsumerStatefulWidget {
  const PortalRidesPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalRidesPanel> createState() => _PortalRidesPanelState();
}

class _PortalRidesPanelState extends ConsumerState<PortalRidesPanel> {
  bool _loading = true;
  String? _activeError;
  String? _historyError;
  Map<String, dynamic>? _activeTrip;
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
      _activeError = null;
      _historyError = null;
    });

    Map<String, dynamic>? activeTrip;
    List<Map<String, dynamic>> trips = const [];
    String? activeError;
    String? historyError;

    try {
      final activeRes = await portalService.getActiveTrip(auth.accessToken);
      final trip = activeRes['trip'];
      if (trip is Map) {
        activeTrip = Map<String, dynamic>.from(trip);
      }
    } catch (_) {
      activeError = T.portal('portal.rides.activeUnavailable');
    }

    try {
      final historyRes = await portalService.listMyTrips(auth.accessToken, limit: 300);
      trips = portalMapList(historyRes, 'trips');
    } catch (_) {
      historyError = T.portal('portal.rides.historyUnavailable');
    }

    if (!mounted) return;
    setState(() {
      _activeTrip = activeTrip;
      _trips = trips;
      _activeError = activeError;
      _historyError = historyError;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveMapHref = widget.area == PortalArea.driver ? Routes.driverLiveMap : Routes.clientLiveMap;
    final activeTripId = portalStr(_activeTrip?['id'], '');
    final hasActiveTrip = activeTripId.isNotEmpty;

    return AdminListStack(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                T.portal('portal.rides.subtitle'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ShadButton.ghost(
              onPressed: _loading ? null : _load,
              child: const Text('Refresh'),
            ),
          ],
        ),
        if (_activeError != null) portalError(_activeError!),
        if (hasActiveTrip)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.portal('portal.rides.activeTrip'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: portalStr(_activeTrip?['status'], 'active'),
                      variant: portalTripStatus(portalStr(_activeTrip?['status'], 'active')),
                    ),
                    Text(activeTripId, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                RyvoButton(
                  onPressed: () => context.go(liveMapHref),
                  size: ShadButtonSize.sm,
                  child: Text(T.portal('portal.rides.trackOnMap')),
                ),
              ],
            ),
          ),
        if (_historyError != null) portalError(_historyError!),
        AdminTableCard(
          child: AdminTable(
            child: DataTable(
              columns: [
                DataColumn(label: Text(T.portal('portal.rides.columns.when'))),
                DataColumn(label: Text(T.portal('portal.rides.columns.route'))),
                DataColumn(label: Text(T.portal('portal.rides.columns.status'))),
              ],
              rows: _buildRows(context),
            ),
          ),
          isEmpty: !_loading && _historyError == null && _trips.isEmpty,
          empty: portalEmpty(T.nav('common.noData')),
        ),
        if (!_loading && _historyError == null && _trips.isEmpty && !hasActiveTrip)
          Column(
            children: [
              const Icon(LucideIcons.car, size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              Text(T.portal('portal.rides.emptyHint')),
              const SizedBox(height: 10),
              RyvoButton(
                onPressed: () => context.go(liveMapHref),
                intent: RyvoButtonIntent.outline,
                size: ShadButtonSize.sm,
                child: Text(T.portal('portal.nav.liveMap')),
              ),
            ],
          ),
      ],
    );
  }

  List<DataRow> _buildRows(BuildContext context) {
    if (_loading) {
      return [
        DataRow(cells: [
          DataCell(SizedBox(width: 160, child: Text(T.nav('common.loading')))),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
        ]),
      ];
    }

    if (_trips.isEmpty) return const [];

    return _trips.map((trip) {
      final pickup = portalStr(trip['pickup_address']);
      final dropoff = portalStr(trip['dropoff_address']);
      final status = portalStr(trip['status'], 'unknown');
      final createdAt = portalStr(trip['created_at'], '');
      return DataRow(
        cells: [
          DataCell(Text(formatLastSeen(createdAt))),
          DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pickup, overflow: TextOverflow.ellipsis),
                  Text('-> $dropoff', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          DataCell(StatusBadge(label: status, variant: portalTripStatus(status))),
        ],
      );
    }).toList(growable: false);
  }
}
