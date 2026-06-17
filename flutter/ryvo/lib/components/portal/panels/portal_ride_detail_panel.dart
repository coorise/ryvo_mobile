import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ryvo/components/portal/google_live_map.dart';
import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/panels/portal_ride_workflow_panel.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/core/common/format_date.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/map_utils.dart';
import 'package:ryvo/services/index.dart';

class PortalRideDetailPanel extends ConsumerStatefulWidget {
  const PortalRideDetailPanel({super.key, required this.area, required this.tripId});

  final PortalArea area;
  final String tripId;

  @override
  ConsumerState<PortalRideDetailPanel> createState() => _PortalRideDetailPanelState();
}

class _PortalRideDetailPanelState extends ConsumerState<PortalRideDetailPanel> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _trip;
  Map<String, dynamic>? _activeTripData;

  static const _steps = [
    'driver_en_route',
    'driver_arrived',
    'rider_picked_up',
    'in_progress',
    'completed',
  ];

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
      final activeRes = await tripService.getActiveTrip(auth.accessToken);
      Map<String, dynamic>? trip;
      final activeTrip = activeRes['trip'];
      if (activeTrip is Map && portalStr(activeTrip['id']) == widget.tripId) {
        trip = Map<String, dynamic>.from(activeTrip);
      } else {
        final historyRes = await portalService.listMyTrips(auth.accessToken, limit: 300);
        for (final item in portalMapList(historyRes, 'trips')) {
          if (portalStr(item['id']) == widget.tripId) {
            trip = item;
            break;
          }
        }
      }
      if (trip == null) {
        throw Exception('trip not found');
      }
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _activeTripData = activeRes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.rides.detailUnavailable');
        _loading = false;
      });
    }
  }

  LatLng? _coord(Map<String, dynamic>? trip, String latKey, String lngKey) {
    if (trip == null) return null;
    final lat = parseCoord(trip[latKey]);
    final lng = parseCoord(trip[lngKey]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Widget _stepsCard() {
    final status = portalStr(_trip?['status'], 'unknown');
    final currentIndex = _steps.indexOf(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(T.portal('portal.rides.stepsTitle'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      i <= currentIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: i <= currentIndex ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(T.portal('portal.rides.steps.${_steps[i]}'))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    final trip = _trip!;
    final pickup = _coord(trip, 'pickup_lat', 'pickup_lng');
    final dropoff = _coord(trip, 'dropoff_lat', 'dropoff_lng');
    final isActive = !const {'completed', 'cancelled', 'canceled'}.contains(portalStr(trip['status']));
    final mapTab = (pickup != null || dropoff != null)
        ? GoogleLiveMap(
            drivers: const [],
            mapCenter: pickup ?? dropoff ?? defaultMapCenter,
            pickup: pickup,
            dropoff: dropoff,
            height: 260,
          )
        : portalEmpty(T.portal('portal.rides.mapUnavailable'));
    final tabs = [
      T.portal('portal.rides.tabs.map'),
      T.portal('portal.rides.tabs.progress'),
      if (isActive) T.portal('portal.rides.tabs.actions'),
    ];
    final tabChildren = [
      mapTab,
      _stepsCard(),
      if (isActive)
        PortalRideWorkflowPanel(
          area: widget.area,
          mode: PortalRideWorkflowMode.driving,
          activeTripData: _activeTripData,
          onChanged: _load,
          pickup: pickup,
          dropoff: dropoff,
        ),
    ];

    return AdminListStack(
      children: [
        Card(
          child: ListTile(
            title: Text(T.portal('portal.rides.detailTitle')),
            subtitle: Text('${portalStr(trip['pickup_address'])} → ${portalStr(trip['dropoff_address'])}'),
            trailing: StatusBadge(
              label: portalStr(trip['status'], 'unknown'),
              variant: portalTripStatus(portalStr(trip['status'], 'unknown')),
            ),
          ),
        ),
        Text(
          formatLastSeen(portalStr(trip['created_at'])),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        AdminMobileColumnTabs(
          scrollableOnMobile: true,
          tabHeight: 360,
          tabs: tabs,
          children: tabChildren,
        ),
      ],
    );
  }
}

String rideDetailPath(PortalArea area, String tripId) {
  return area == PortalArea.driver ? '/driver/drive/$tripId' : '/client/drive/$tripId';
}
