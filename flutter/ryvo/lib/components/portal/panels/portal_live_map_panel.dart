import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/google_live_map.dart';
import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
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
  final _searchController = TextEditingController();
  Timer? _polling;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _drivers = const [];
  List<Map<String, dynamic>> _places = const [];
  Map<String, dynamic>? _activeTrip;
  String? _selectedDriverId;
  LatLng? _placeTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      if (!apiClientTestMode) {
        _polling = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final auth = useAuth(ref);
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final nearby = widget.area == PortalArea.driver
          ? await mapService.listOnlineDrivers(auth.accessToken)
          : await mapService.listNearbyDrivers(auth.accessToken);
      final activeRes = await tripService.getActiveTrip(auth.accessToken);
      if (!mounted) return;
      setState(() {
        _drivers = portalMapList(nearby, 'drivers');
        final trip = activeRes['trip'];
        _activeTrip = trip is Map ? Map<String, dynamic>.from(trip) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.liveMap.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _places = const []);
      return;
    }
    final auth = useAuth(ref);
    try {
      final res = widget.area == PortalArea.driver
          ? await mapService.searchPlaces(auth.accessToken, query)
          : await mapService.searchPlacesPortal(auth.accessToken, query);
      if (!mounted) return;
      setState(() => _places = portalMapList(res, 'places'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _places = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    final mapCenter = resolveMapCenter(null);

    Widget mapWithSidebar() {
      return AdminListStack(
        children: [
          GoogleLiveMap(
            drivers: _drivers,
            mapCenter: mapCenter,
            selectedDriverId: _selectedDriverId,
            placeTarget: _placeTarget,
            onSelectDriver: (driver) => setState(() => _selectedDriverId = driverId(driver)),
            height: 320,
          ),
          if (widget.area == PortalArea.client)
            AdminSearchToolbar(
              value: _searchController.text,
              onChanged: (value) {
                _searchController.text = value;
                _searchController.selection = TextSelection.collapsed(offset: value.length);
              },
              placeholder: T.portal('portal.liveMap.searchPlaceholder'),
              filters: [
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _searchPlaces,
                  child: Text(T.portal('portal.liveMap.search')),
                ),
              ],
            ),
          if (_places.isNotEmpty)
            Card(
              child: Column(
                children: _places.take(5).map((place) {
                  return ListTile(
                    title: Text(portalStr(place['label'], portalStr(place['name']))),
                    subtitle: Text(portalStr(place['address'])),
                    onTap: () {
                      final lat = parseCoord(place['lat']);
                      final lng = parseCoord(place['lng']);
                      if (lat == null || lng == null) return;
                      setState(() {
                        _placeTarget = LatLng(lat, lng);
                        _places = const [];
                      });
                    },
                  );
                }).toList(growable: false),
              ),
            ),
          if (_drivers.isNotEmpty)
            AdminTableCard(
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
            ),
        ],
      );
    }

    Widget incomingWorkflow() {
      if (_activeTrip == null) return portalEmpty(T.portal('portal.liveMap.noIncoming'));
      final status = portalStr(_activeTrip?['status'], 'unknown');
      return Card(
        child: ListTile(
          title: Text(T.portal('portal.liveMap.incomingTitle')),
          subtitle: Text('${portalStr(_activeTrip?['id'])} · $status'),
          trailing: StatusBadge(label: status, variant: portalTripStatus(status)),
        ),
      );
    }

    Widget drivingWorkflow() {
      if (_activeTrip == null) return portalEmpty(T.portal('portal.liveMap.noDriving'));
      final status = portalStr(_activeTrip?['status'], 'unknown');
      return AdminListStack(
        children: [
          Card(
            child: ListTile(
              title: Text(T.portal('portal.liveMap.tripActive')),
              subtitle: Text(portalStr(_activeTrip?['id'])),
              trailing: StatusBadge(label: status, variant: portalTripStatus(status)),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(T.portal('portal.liveMap.route')),
              subtitle: Text(
                '${portalStr(_activeTrip?['pickup_address'])} -> ${portalStr(_activeTrip?['dropoff_address'])}',
              ),
            ),
          ),
        ],
      );
    }

    if (widget.area == PortalArea.driver) {
      return PortalTabScaffold(
        tabs: [
          T.portal('portal.liveMap.tabs.live'),
          T.portal('portal.liveMap.tabs.incoming'),
          T.portal('portal.liveMap.tabs.driving'),
        ],
        children: [
          Padding(padding: const EdgeInsets.all(12), child: mapWithSidebar()),
          Padding(padding: const EdgeInsets.all(12), child: incomingWorkflow()),
          Padding(padding: const EdgeInsets.all(12), child: drivingWorkflow()),
        ],
      );
    }

    return PortalTabScaffold(
      tabs: [
        T.portal('portal.liveMap.tabs.goTo'),
        T.portal('portal.liveMap.tabs.requesting'),
        T.portal('portal.liveMap.tabs.driving'),
      ],
      children: [
        Padding(padding: const EdgeInsets.all(12), child: mapWithSidebar()),
        Padding(padding: const EdgeInsets.all(12), child: incomingWorkflow()),
        Padding(padding: const EdgeInsets.all(12), child: drivingWorkflow()),
      ],
    );
  }
}
