import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryvo/configs/env.dart';
import 'package:ryvo/lib/map_utils.dart';

class GoogleLiveMap extends StatefulWidget {
  const GoogleLiveMap({
    super.key,
    required this.drivers,
    required this.mapCenter,
    this.selectedDriverId,
    this.onSelectDriver,
    this.placeTarget,
    this.pickup,
    this.dropoff,
    this.height = 280,
  });

  final List<Map<String, dynamic>> drivers;
  final LatLng mapCenter;
  final String? selectedDriverId;
  final ValueChanged<Map<String, dynamic>>? onSelectDriver;
  final LatLng? placeTarget;
  final LatLng? pickup;
  final LatLng? dropoff;
  final double height;

  @override
  State<GoogleLiveMap> createState() => _GoogleLiveMapState();
}

class _GoogleLiveMapState extends State<GoogleLiveMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant GoogleLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDriverId != oldWidget.selectedDriverId &&
        widget.selectedDriverId != null) {
      _focusSelectedDriver();
    } else if (widget.placeTarget != oldWidget.placeTarget && widget.placeTarget != null) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(widget.placeTarget!, 14));
    } else if ((widget.pickup != oldWidget.pickup || widget.dropoff != oldWidget.dropoff) &&
        (widget.pickup != null || widget.dropoff != null)) {
      _fitRoute();
    }
  }

  void _focusSelectedDriver() {
    final id = widget.selectedDriverId;
    if (id == null) return;
    for (final driver in widget.drivers) {
      if (driverId(driver) != id) continue;
      final pos = driverPosition(driver);
      if (pos == null) return;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
      return;
    }
  }

  void _fitRoute() {
    final points = <LatLng>[];
    if (widget.pickup != null) points.add(widget.pickup!);
    if (widget.dropoff != null) points.add(widget.dropoff!);
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }
    var bounds = LatLngBounds(southwest: points.first, northeast: points.first);
    for (final point in points.skip(1)) {
      bounds = LatLngBounds(
        southwest: LatLng(
          bounds.southwest.latitude < point.latitude
              ? bounds.southwest.latitude
              : point.latitude,
          bounds.southwest.longitude < point.longitude
              ? bounds.southwest.longitude
              : point.longitude,
        ),
        northeast: LatLng(
          bounds.northeast.latitude > point.latitude
              ? bounds.northeast.latitude
              : point.latitude,
          bounds.northeast.longitude > point.longitude
              ? bounds.northeast.longitude
              : point.longitude,
        ),
      );
    }
    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final driver in widget.drivers) {
      final id = driverId(driver);
      if (id.isEmpty) continue;
      final pos = driverPosition(driver);
      if (pos == null) continue;
      final onTrip = driverOnTrip(driver);
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: pos,
          infoWindow: InfoWindow(title: driverName(driver)),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            onTrip ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
          ),
          onTap: () => widget.onSelectDriver?.call(driver),
        ),
      );
    }

    final place = widget.placeTarget;
    if (place != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__place_target__'),
          position: place,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    final pickup = widget.pickup;
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__pickup__'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    final dropoff = widget.dropoff;
    if (dropoff != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__dropoff__'),
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Dropoff'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final pickup = widget.pickup;
    final dropoff = widget.dropoff;
    if (pickup == null || dropoff == null) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('__route_preview__'),
        points: [pickup, dropoff],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (Env.googleMapsApiKey.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Google Maps API key missing. Set GOOGLE_MAPS_API_KEY in dart_defines.json.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.mapCenter,
            zoom: 12,
          ),
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            _focusSelectedDriver();
            _fitRoute();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
