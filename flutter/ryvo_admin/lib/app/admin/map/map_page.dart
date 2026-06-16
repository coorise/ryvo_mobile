import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/google_live_map.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/lib/map_utils.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminMapPage extends ConsumerStatefulWidget {
  const AdminMapPage({super.key});

  @override
  ConsumerState<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends ConsumerState<AdminMapPage> {
  Future<Map<String, dynamic>>? _driversFuture;
  Future<Map<String, dynamic>>? _settingsFuture;
  final TextEditingController _placeQueryCtrl = TextEditingController();
  String _query = '';
  String? _selectedDriverId;
  LatLng? _placeTarget;
  List<Map<String, dynamic>> _placeSuggestions = const [];
  bool _placeLoading = false;
  Timer? _refreshTimer;
  Timer? _placeDebounce;

  @override
  void initState() {
    super.initState();
    _settingsFuture = adminService.getPublicSettings();
    _driversFuture = _loadDrivers();
    _placeQueryCtrl.addListener(_onPlaceQueryChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _placeDebounce?.cancel();
    _placeQueryCtrl.dispose();
    super.dispose();
  }

  void _onPlaceQueryChanged() {
    _placeDebounce?.cancel();
    _placeDebounce = Timer(const Duration(milliseconds: 280), _fetchPlaceSuggestions);
  }

  Future<void> _fetchPlaceSuggestions() async {
    final q = _placeQueryCtrl.text.trim();
    if (q.length < 2) {
      if (mounted) setState(() => _placeSuggestions = const []);
      return;
    }
    setState(() => _placeLoading = true);
    try {
      final settings = await (_settingsFuture ?? adminService.getPublicSettings());
      final center = resolveMapCenter(settings);
      final res = await routingService.autocompletePlaces(
        ref.read(authProvider).accessToken,
        q,
        lat: center.latitude,
        lng: center.longitude,
      );
      final raw = res['predictions'];
      final suggestions = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(growable: false)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _placeSuggestions = suggestions);
    } catch (_) {
      if (mounted) setState(() => _placeSuggestions = const []);
    } finally {
      if (mounted) setState(() => _placeLoading = false);
    }
  }

  Future<void> _selectPlaceSuggestion(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id']?.toString();
    if (placeId == null || placeId.isEmpty) return;
    setState(() {
      _placeLoading = true;
      _placeSuggestions = const [];
    });
    try {
      final res = await routingService.getPlaceDetails(
        ref.read(authProvider).accessToken,
        placeId,
      );
      final place = res['place'];
      if (place is! Map) return;
      final lat = parseCoord(place['lat']);
      final lng = parseCoord(place['lng']);
      if (lat == null || lng == null) return;
      setState(() {
        _placeTarget = LatLng(lat, lng);
        _placeQueryCtrl.text = place['name']?.toString() ??
            prediction['description']?.toString() ??
            '';
      });
    } finally {
      if (mounted) setState(() => _placeLoading = false);
    }
  }

  Future<void> _searchPlaceDirectly() async {
    final q = _placeQueryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _placeLoading = true;
      _placeSuggestions = const [];
    });
    try {
      final res = await mapService.searchPlaces(
        ref.read(authProvider).accessToken,
        q,
      );
      final raw = res['places'];
      final places = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (places.isEmpty) return;
      final place = places.first;
      final lat = parseCoord(place['lat']);
      final lng = parseCoord(place['lng']);
      if (lat == null || lng == null) return;
      setState(() {
        _placeTarget = LatLng(lat, lng);
        _placeQueryCtrl.text = place['name']?.toString() ?? q;
      });
    } finally {
      if (mounted) setState(() => _placeLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadDrivers() {
    return mapService.listOnlineDrivers(
      ref.read(authProvider).accessToken,
      query: _query,
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) {
      setState(() => _driversFuture = _loadDrivers());
      await _driversFuture;
      return;
    }
    try {
      final data = await _loadDrivers();
      if (!mounted) return;
      setState(() => _driversFuture = Future.value(data));
    } catch (_) {
      // Keep previous snapshot on background refresh failures.
    }
  }

  void _selectDriver(Map<String, dynamic> driver) {
    setState(() => _selectedDriverId = driverId(driver));
  }

  List<Map<String, dynamic>> _parseDrivers(Map<String, dynamic>? data) {
    final raw = data?['drivers'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Widget _buildPlaceSearch(LatLng mapCenter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSearchToolbar(
          value: _placeQueryCtrl.text,
          onChanged: (v) {
            _placeQueryCtrl.value = _placeQueryCtrl.value.copyWith(
              text: v,
              selection: TextSelection.collapsed(offset: v.length),
            );
          },
          placeholder: 'Search place on map',
          filters: [
            if (_placeLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            FilledButton(
              onPressed: _placeLoading ? null : _searchPlaceDirectly,
              child: const Text('Go'),
            ),
          ],
        ),
        if (_placeSuggestions.isNotEmpty)
          AdminTableCard(
            isEmpty: false,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _placeSuggestions.length.clamp(0, 6),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _placeSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 18),
                  title: Text(
                    item['description']?.toString() ?? 'Place',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlaceSuggestion(item),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return PermissionGate(
      permissions: const ['map:read', 'rides:read'],
      fallback: const Center(child: Text('No access to map data.')),
      child: isWide
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMapContent(isWide: true),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMapContent(isWide: false),
            ),
    );
  }

  Widget _buildMapContent({required bool isWide}) {
    return AdminListStack(
      children: [
        AdminPageHeader(
          title: 'Live Map',
          subtitle: 'Online drivers, place search, and live stats.',
          action: OutlinedButton.icon(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ),
        AdminSearchToolbar(
          value: _query,
          onChanged: (v) => setState(() => _query = v),
          placeholder: 'Search driver by name or id',
          filters: [
            FilledButton(onPressed: () => _refresh(), child: const Text('Apply')),
          ],
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: _settingsFuture,
          builder: (context, settingsSnapshot) {
            final mapCenter = resolveMapCenter(settingsSnapshot.data);

            return FutureBuilder<Map<String, dynamic>>(
              future: _driversFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError && !snapshot.hasData) {
                  return AdminTableCard(
                    isEmpty: true,
                    empty: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Failed to load online drivers: ${snapshot.error}',
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final drivers = _parseDrivers(snapshot.data);
                final online = drivers.where((d) => d['is_online'] == true).length;
                final onTrip = drivers.where(driverOnTrip).length;

                final mapWidget = GoogleLiveMap(
                  drivers: drivers,
                  mapCenter: mapCenter,
                  selectedDriverId: _selectedDriverId,
                  onSelectDriver: _selectDriver,
                  placeTarget: _placeTarget,
                  height: isWide ? 360 : 320,
                );

                final stats = AdminCollapsibleOverview(
                  summary:
                      '${drivers.length} visible · $online online · $onTrip on trip',
                  child: AdminStatGrid(
                    children: [
                      AdminStatCard(
                        label: 'Visible Drivers',
                        value: '${drivers.length}',
                        icon: Icons.directions_car_filled,
                      ),
                      AdminStatCard(
                        label: 'Online',
                        value: '$online',
                        icon: Icons.wifi_tethering,
                        tone: AdminStatTone.success,
                      ),
                      AdminStatCard(
                        label: 'On Trip',
                        value: '$onTrip',
                        icon: Icons.alt_route,
                        tone: AdminStatTone.info,
                      ),
                      AdminStatCard(
                        label: 'Idle',
                        value: '${online - onTrip}',
                        icon: Icons.pause_circle_outline,
                        tone: AdminStatTone.warning,
                      ),
                    ],
                  ),
                );

                final driverList = _buildDriverList(drivers);
                final placeSearch = _buildPlaceSearch(mapCenter);

                if (isWide) {
                  return AdminListStack(
                    children: [
                      placeSearch,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: mapWidget),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: stats),
                        ],
                      ),
                      driverList,
                    ],
                  );
                }

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      placeSearch,
                      const TabBar(
                        tabs: [
                          Tab(text: 'Map'),
                          Tab(text: 'Stats'),
                          Tab(text: 'Drivers'),
                        ],
                      ),
                      SizedBox(
                        height: 420,
                        child: TabBarView(
                          children: [
                            mapWidget,
                            SingleChildScrollView(child: stats),
                            _buildDriverList(drivers, scrollable: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDriverList(
    List<Map<String, dynamic>> drivers, {
    bool scrollable = false,
  }) {
    return AdminTableCard(
      isEmpty: drivers.isEmpty,
      empty: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No online drivers found.'),
      ),
      child: ListView.separated(
        shrinkWrap: !scrollable,
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: drivers.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final id = driverId(driver);
          final selected = _selectedDriverId == id;
          final pos = driverPosition(driver);
          return ListTile(
            selected: selected,
            onTap: () => _selectDriver(driver),
            title: Text(driverName(driver)),
            subtitle: Text(
              'Status: ${driver['status'] ?? '—'} · '
              '${pos == null ? 'No GPS' : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'} · '
              'Updated: ${driver['updated_at'] ?? '—'}',
            ),
            trailing: StatusBadge(
              label: driver['is_online'] == true ? 'Online' : 'Offline',
              variant: driver['is_online'] == true
                  ? StatusBadgeVariant.success
                  : StatusBadgeVariant.defaultVariant,
            ),
          );
        },
      ),
    );
  }
}
