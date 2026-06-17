import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/google_live_map.dart';
import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/panels/portal_ride_workflow_panel.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/components/portal/portal_place_search.dart';
import 'package:ryvo/components/portal/portal_tab_scaffold.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/lib/map_utils.dart';
import 'package:ryvo/services/index.dart';

class PortalLiveMapPanel extends ConsumerStatefulWidget {
  const PortalLiveMapPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalLiveMapPanel> createState() => _PortalLiveMapPanelState();
}

class _PortalLiveMapPanelState extends ConsumerState<PortalLiveMapPanel> {
  Timer? _polling;
  bool _loading = true;
  bool _presenceBusy = false;
  String? _error;
  List<Map<String, dynamic>> _drivers = const [];
  Map<String, dynamic>? _activeTripData;
  String? _selectedDriverId;
  LatLng? _placeTarget;
  LatLng? _pickup;
  LatLng? _dropoff;
  LatLng? _searchedPlace;
  bool _isOnline = false;
  double _zoneMultiplier = 1.0;
  String? _lastIncomingAssignmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      if (!apiClientTestMode) {
        _polling = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  String get _phase => portalStr(_activeTripData?['phase'], 'idle');

  Map<String, dynamic>? get _trip {
    final value = _activeTripData?['trip'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  String? get _tripStatus => _trip?['status']?.toString();

  bool get _focusDriving {
    final status = _tripStatus;
    return status == 'in_progress' || status == 'rider_picked_up';
  }

  bool get _showDrivingTab {
    return _phase == 'active_trip' || _phase == 'awaiting_payment';
  }

  String? get _selectedTabId {
    if (_focusDriving) return 'driving';
    if (widget.area == PortalArea.driver) {
      if (_phase == 'driver_offer') return 'incoming';
      if (_phase == 'active_trip' || _phase == 'awaiting_payment') return 'driving';
      return 'live';
    }
    if (_phase == 'pre_trip') return 'requesting';
    if (_phase == 'active_trip' || _phase == 'awaiting_payment') return 'driving';
    return 'go-to';
  }

  LatLng get _mapCenter => resolveMapCenter(null);

  Future<void> _load({bool silent = false}) async {
    final auth = useAuth(ref);
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final driversFuture = widget.area == PortalArea.client
          ? mapService.listNearbyDrivers(auth.accessToken)
          : Future<Map<String, dynamic>>.value({'drivers': <Map<String, dynamic>>[]});
      final activeFuture = tripService.getActiveTrip(auth.accessToken);
      final results = await Future.wait([driversFuture, activeFuture]);
      if (!mounted) return;

      final activeRes = Map<String, dynamic>.from(results[1] as Map);
      final trip = activeRes['trip'];
      LatLng? pickup;
      LatLng? dropoff;
      if (trip is Map) {
        final tripMap = Map<String, dynamic>.from(trip);
        final pickupLat = parseCoord(tripMap['pickup_lat']);
        final pickupLng = parseCoord(tripMap['pickup_lng']);
        final dropoffLat = parseCoord(tripMap['dropoff_lat']);
        final dropoffLng = parseCoord(tripMap['dropoff_lng']);
        if (pickupLat != null && pickupLng != null) pickup = LatLng(pickupLat, pickupLng);
        if (dropoffLat != null && dropoffLng != null) dropoff = LatLng(dropoffLat, dropoffLng);
      } else {
        final request = activeRes['request'];
        if (request is Map) {
          final requestMap = Map<String, dynamic>.from(request);
          final pickupLat = parseCoord(requestMap['pickup_lat']);
          final pickupLng = parseCoord(requestMap['pickup_lng']);
          final dropoffLat = parseCoord(requestMap['dropoff_lat']);
          final dropoffLng = parseCoord(requestMap['dropoff_lng']);
          if (pickupLat != null && pickupLng != null) pickup = LatLng(pickupLat, pickupLng);
          if (dropoffLat != null && dropoffLng != null) dropoff = LatLng(dropoffLat, dropoffLng);
        }
      }

      setState(() {
        _drivers = portalMapList(results[0], 'drivers');
        _activeTripData = activeRes;
        if (pickup != null) _pickup = pickup;
        if (dropoff != null) _dropoff = dropoff;
        _loading = false;
      });
      _maybeShowIncomingOffer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.liveMap.unavailable');
        _loading = false;
      });
    }
  }

  void _maybeShowIncomingOffer() {
    if (widget.area != PortalArea.driver || _phase != 'driver_offer') return;
    final assignment = _activeTripData?['assignment'];
    if (assignment is! Map) return;
    final assignmentId = portalStr(assignment['id']);
    if (assignmentId.isEmpty || assignmentId == _lastIncomingAssignmentId) return;
    _lastIncomingAssignmentId = assignmentId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: PortalRideWorkflowPanel(
            area: PortalArea.driver,
            mode: PortalRideWorkflowMode.incoming,
            activeTripData: _activeTripData,
            onChanged: () {
              Navigator.pop(sheetContext);
              _load(silent: true);
            },
          ),
        ),
      );
    });
  }

  Future<void> _toggleOnline(bool online) async {
    setState(() => _presenceBusy = true);
    try {
      final auth = useAuth(ref);
      final center = _placeTarget ?? _mapCenter;
      await locationService.setOnline(
        auth.accessToken,
        isOnline: online,
        lat: center.latitude,
        lng: center.longitude,
      );
      if (!mounted) return;
      setState(() => _isOnline = online);
      await _load(silent: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.ride.actionFailed'))),
      );
    } finally {
      if (mounted) setState(() => _presenceBusy = false);
    }
  }

  void _onPlaceSelected({required LatLng position, required String label, String? address}) {
    setState(() {
      _searchedPlace = position;
      _placeTarget = position;
    });
  }

  Widget _mapSection({double height = 320}) {
    return GoogleLiveMap(
      drivers: _drivers,
      mapCenter: _mapCenter,
      selectedDriverId: _selectedDriverId,
      placeTarget: _placeTarget ?? _searchedPlace,
      pickup: _pickup,
      dropoff: _dropoff,
      onSelectDriver: (driver) => setState(() => _selectedDriverId = driverId(driver)),
      height: height,
    );
  }

  Widget _driversList() {
    if (widget.area != PortalArea.client || _drivers.isEmpty) {
      return const SizedBox.shrink();
    }
    return AdminTableCard(
      child: AdminTable(
        child: DataTable(
          columns: [
            DataColumn(label: Text(T.portal('portal.liveMap.columns.driver'))),
            DataColumn(label: Text(T.portal('portal.liveMap.columns.status'))),
          ],
          rows: _drivers.take(20).map((driver) {
            final status = portalStr(driver['status'], 'offline');
            return DataRow(
              selected: _selectedDriverId == driverId(driver),
              onSelectChanged: (_) => setState(() => _selectedDriverId = driverId(driver)),
              cells: [
                DataCell(Text(driverName(driver))),
                DataCell(StatusBadge(label: status, variant: portalTripStatus(status))),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  Widget _placeSearchActions() {
    if (_searchedPlace == null) return const SizedBox.shrink();
    if (widget.area != PortalArea.client) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: () => setState(() {
            _pickup = _searchedPlace;
            _placeTarget = _searchedPlace;
          }),
          child: Text(T.portal('portal.liveMap.setPickup')),
        ),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: () => setState(() {
            _dropoff = _searchedPlace;
            _placeTarget = _searchedPlace;
          }),
          child: Text(T.portal('portal.liveMap.setDropoff')),
        ),
      ],
    );
  }

  Widget _driverPresenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(T.portal('portal.liveMap.driverSubtitle')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isOnline
                        ? T.portal('portal.liveMap.goOffline')
                        : T.portal('portal.liveMap.goOnline'),
                  ),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _presenceBusy ? null : _toggleOnline,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(T.portal('portal.liveMap.zonePrice')),
            Slider(
              value: _zoneMultiplier,
              min: 1,
              max: 2.5,
              divisions: 6,
              label: '${_zoneMultiplier.toStringAsFixed(1)}x',
              onChanged: _isOnline
                  ? (value) => setState(() => _zoneMultiplier = value)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: AdminListStack(
        children: [
          PortalPlaceSearch(
            mapCenter: _mapCenter,
            onPlaceSelected: _onPlaceSelected,
          ),
          _placeSearchActions(),
          _mapSection(),
          if (widget.area == PortalArea.driver) _driverPresenceCard(),
          _driversList(),
          PortalRideWorkflowPanel(
            area: widget.area,
            mode: PortalRideWorkflowMode.booking,
            activeTripData: _activeTripData,
            onChanged: () => _load(silent: true),
            pickup: _pickup,
            dropoff: _dropoff,
          ),
        ],
      ),
    );
  }

  Widget _workflowTab(PortalRideWorkflowMode mode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: AdminListStack(
        children: [
          if (mode == PortalRideWorkflowMode.driving) _mapSection(height: 280),
          PortalRideWorkflowPanel(
            area: widget.area,
            mode: mode,
            activeTripData: _activeTripData,
            onChanged: () => _load(silent: true),
            pickup: _pickup,
            dropoff: _dropoff,
          ),
          if (mode == PortalRideWorkflowMode.driving && _trip != null)
            Card(
              child: ListTile(
                title: Text(T.portal('portal.liveMap.route')),
                subtitle: Text(
                  '${portalStr(_trip?['pickup_address'])} → ${portalStr(_trip?['dropoff_address'])}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    if (widget.area == PortalArea.driver) {
      return PortalTabScaffold(
        selectedTabId: _selectedTabId,
        tabs: [
          PortalTabItem(
            id: 'live',
            label: T.portal('portal.liveMap.tabs.live'),
            visible: !_focusDriving,
            child: _liveTabContent(),
          ),
          PortalTabItem(
            id: 'incoming',
            label: T.portal('portal.liveMap.tabs.incoming'),
            visible: !_focusDriving,
            child: _workflowTab(PortalRideWorkflowMode.incoming),
          ),
          PortalTabItem(
            id: 'driving',
            label: T.portal('portal.liveMap.tabs.driving'),
            visible: _showDrivingTab || _focusDriving,
            child: _workflowTab(PortalRideWorkflowMode.driving),
          ),
        ],
      );
    }

    return PortalTabScaffold(
      selectedTabId: _selectedTabId,
      tabs: [
        PortalTabItem(
          id: 'go-to',
          label: T.portal('portal.liveMap.tabs.goTo'),
          visible: !_focusDriving,
          child: _liveTabContent(),
        ),
        PortalTabItem(
          id: 'requesting',
          label: T.portal('portal.liveMap.tabs.requesting'),
          visible: !_focusDriving,
          child: _workflowTab(PortalRideWorkflowMode.requesting),
        ),
        PortalTabItem(
          id: 'driving',
          label: T.portal('portal.liveMap.tabs.driving'),
          visible: _showDrivingTab || _focusDriving,
          child: _workflowTab(PortalRideWorkflowMode.driving),
        ),
      ],
    );
  }
}
