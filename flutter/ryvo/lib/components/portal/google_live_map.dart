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
    this.height = 280,
  });

  final List<Map<String, dynamic>> drivers;
  final LatLng mapCenter;
  final String? selectedDriverId;
  final ValueChanged<Map<String, dynamic>>? onSelectDriver;
  final LatLng? placeTarget;
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
    } else if (widget.placeTarget != oldWidget.placeTarget &&
        widget.placeTarget != null) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.placeTarget!, 14),
      );
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
            onTrip
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueGreen,
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    return markers;
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
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            _focusSelectedDriver();
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
