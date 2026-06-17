import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/map_utils.dart';
import 'package:ryvo/services/index.dart';

typedef PortalPlaceSelected = void Function({
  required LatLng position,
  required String label,
  String? address,
});

class PortalPlaceSearch extends ConsumerStatefulWidget {
  const PortalPlaceSearch({
    super.key,
    required this.mapCenter,
    required this.onPlaceSelected,
    this.placeholder,
    this.usePortalScope = true,
    this.dense = false,
  });

  final LatLng mapCenter;
  final PortalPlaceSelected onPlaceSelected;
  final String? placeholder;
  final bool usePortalScope;
  final bool dense;

  @override
  ConsumerState<PortalPlaceSearch> createState() => _PortalPlaceSearchState();
}

class _PortalPlaceSearchState extends ConsumerState<PortalPlaceSearch> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _fetchSuggestions);
  }

  Future<void> _fetchSuggestions() async {
    final query = _controller.text.trim();
    if (query.length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = useAuth(ref);
      final res = await routingService.autocompletePlaces(
        auth.accessToken,
        query,
        lat: widget.mapCenter.latitude,
        lng: widget.mapCenter.longitude,
      );
      final raw = res['predictions'];
      final suggestions = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _suggestions = suggestions);
    } catch (_) {
      if (mounted) setState(() => _suggestions = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolvePlace({String? placeId, String? query}) async {
    setState(() {
      _loading = true;
      _suggestions = const [];
    });
    try {
      final auth = useAuth(ref);
      Map<String, dynamic>? place;
      if (placeId != null && placeId.isNotEmpty) {
        final res = await routingService.getPlaceDetails(auth.accessToken, placeId);
        if (res['place'] is Map) {
          place = Map<String, dynamic>.from(res['place'] as Map);
        }
      } else {
        final q = (query ?? _controller.text).trim();
        if (q.isEmpty) return;
        final res = widget.usePortalScope
            ? await mapService.searchPlacesPortal(auth.accessToken, q)
            : await mapService.searchPlaces(auth.accessToken, q);
        final places = res['places'];
        if (places is List && places.isNotEmpty && places.first is Map) {
          place = Map<String, dynamic>.from(places.first as Map);
        }
      }
      if (place == null) return;
      final lat = parseCoord(place['lat']);
      final lng = parseCoord(place['lng']);
      if (lat == null || lng == null) return;
      final label = portalStr(
        place['name'],
        portalStr(place['label'], _controller.text.trim()),
      );
      final address = portalStr(place['address'], '');
      _controller.text = label;
      widget.onPlaceSelected(
        position: LatLng(lat, lng),
        label: label,
        address: address.isEmpty ? null : address,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id']?.toString();
    final description = prediction['description']?.toString() ?? '';
    if (description.isNotEmpty) _controller.text = description;
    await _resolvePlace(placeId: placeId, query: description);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSearchToolbar(
          value: _controller.text,
          onChanged: (value) {
            _controller.text = value;
            _controller.selection = TextSelection.collapsed(offset: value.length);
          },
          placeholder: widget.placeholder ?? T.portal('portal.liveMap.searchPlaceholder'),
          filters: [
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: _loading ? null : () => _resolvePlace(query: _controller.text),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(T.portal('portal.liveMap.search')),
            ),
          ],
        ),
        if (_loading && _suggestions.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: widget.dense ? 4 : 8),
            child: Text(
              T.nav('common.loading'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: EdgeInsets.only(top: widget.dense ? 4 : 8),
            child: Column(
              children: _suggestions.take(6).map((prediction) {
                return ListTile(
                  dense: widget.dense,
                  title: Text(
                    portalStr(prediction['description'], portalStr(prediction['name'])),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(prediction),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }
}
