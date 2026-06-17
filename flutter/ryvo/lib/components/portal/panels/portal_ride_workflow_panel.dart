import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/map_utils.dart';
import 'package:ryvo/services/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PortalRideWorkflowMode { booking, incoming, requesting, driving }

class PortalRideWorkflowPanel extends ConsumerStatefulWidget {
  const PortalRideWorkflowPanel({
    super.key,
    required this.area,
    required this.mode,
    this.activeTripData,
    this.onChanged,
    this.pickup,
    this.dropoff,
  });

  final PortalArea area;
  final PortalRideWorkflowMode mode;
  final Map<String, dynamic>? activeTripData;
  final VoidCallback? onChanged;
  final LatLng? pickup;
  final LatLng? dropoff;

  @override
  ConsumerState<PortalRideWorkflowPanel> createState() => _PortalRideWorkflowPanelState();
}

class _PortalRideWorkflowPanelState extends ConsumerState<PortalRideWorkflowPanel> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LatLng? _pickup;
  LatLng? _dropoff;
  bool _busy = false;
  String? _message;
  String? _estimateText;

  @override
  void initState() {
    super.initState();
    _syncExternalCoords();
  }

  @override
  void didUpdateWidget(covariant PortalRideWorkflowPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup || oldWidget.dropoff != widget.dropoff) {
      _syncExternalCoords();
    }
  }

  void _syncExternalCoords() {
    if (widget.pickup != null) {
      _pickup = widget.pickup;
      if (_pickupController.text.isEmpty) {
        _pickupController.text = T.portal('portal.ride.pickupSet');
      }
    }
    if (widget.dropoff != null) {
      _dropoff = widget.dropoff;
      if (_dropoffController.text.isEmpty) {
        _dropoffController.text = T.portal('portal.ride.dropoffSet');
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  String get _phase => portalStr(widget.activeTripData?['phase'], 'idle');

  Map<String, dynamic>? get _assignment {
    final value = widget.activeTripData?['assignment'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Map<String, dynamic>? get _request {
    final direct = widget.activeTripData?['request'];
    if (direct is Map) return Map<String, dynamic>.from(direct);
    final tripReq = widget.activeTripData?['trip'];
    if (tripReq is Map && tripReq['trip_requests'] is Map) {
      return Map<String, dynamic>.from(tripReq['trip_requests'] as Map);
    }
    return null;
  }

  Map<String, dynamic>? get _trip {
    final value = widget.activeTripData?['trip'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  String? get _requestId => _request?['id']?.toString();
  String? get _assignmentId => _assignment?['id']?.toString();
  String? get _tripId => _trip?['id']?.toString();
  String? get _tripStatus => _trip?['status']?.toString();

  bool get _showBooking =>
      widget.area == PortalArea.client &&
      widget.mode == PortalRideWorkflowMode.booking &&
      (_phase == 'idle' || _phase == 'pre_trip');

  bool get _showRequesting =>
      widget.area == PortalArea.client &&
      (widget.mode == PortalRideWorkflowMode.requesting ||
          widget.mode == PortalRideWorkflowMode.booking) &&
      _phase == 'pre_trip';

  bool get _showIncoming =>
      widget.area == PortalArea.driver &&
      (widget.mode == PortalRideWorkflowMode.incoming ||
          widget.mode == PortalRideWorkflowMode.booking) &&
      _phase == 'driver_offer';

  bool get _showDriving =>
      (widget.mode == PortalRideWorkflowMode.driving ||
          widget.mode == PortalRideWorkflowMode.booking) &&
      (_phase == 'active_trip' || _phase == 'awaiting_payment');

  String? get _driverNextStatus {
    final status = _tripStatus;
    if (status == 'driver_en_route') return 'driver_arrived';
    if (status == 'driver_arrived') return 'rider_picked_up';
    if (status == 'rider_picked_up') return 'in_progress';
    if (status == 'in_progress') return 'completed';
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      widget.onChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _message = T.portal('portal.ride.actionFailed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _estimateFare() async {
    final pickup = _pickup ?? widget.pickup;
    final dropoff = _dropoff ?? widget.dropoff;
    if (pickup == null || dropoff == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      final res = await tripService.estimate(auth.accessToken, {
        'pickup_lat': pickup.latitude,
        'pickup_lng': pickup.longitude,
        'dropoff_lat': dropoff.latitude,
        'dropoff_lng': dropoff.longitude,
        'pickup_address': _pickupController.text.trim().isEmpty ? null : _pickupController.text.trim(),
        'dropoff_address': _dropoffController.text.trim().isEmpty ? null : _dropoffController.text.trim(),
        'vehicle_category': 'economy',
      });
      final estimate = res['estimate'];
      final total = estimate is Map ? estimate['total'] : null;
      if (total == null) throw Exception('missing estimate');
      setState(() {
        _estimateText = T.portal('portal.ride.estimated', {'amount': num.parse('$total').toStringAsFixed(2)});
        _message = _estimateText;
      });
    });
  }

  Future<void> _requestRide() async {
    final pickup = _pickup ?? widget.pickup;
    final dropoff = _dropoff ?? widget.dropoff;
    if (pickup == null || dropoff == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await tripService.requestRide(auth.accessToken, {
        'pickup_lat': pickup.latitude,
        'pickup_lng': pickup.longitude,
        'dropoff_lat': dropoff.latitude,
        'dropoff_lng': dropoff.longitude,
        'pickup_address': _pickupController.text.trim().isEmpty ? null : _pickupController.text.trim(),
        'dropoff_address': _dropoffController.text.trim().isEmpty ? null : _dropoffController.text.trim(),
        'vehicle_category': 'economy',
        'idempotency_key': const Uuid().v4(),
      });
      setState(() => _message = T.portal('portal.ride.requestSent'));
    });
  }

  Future<void> _acceptAssignment() async {
    final id = _assignmentId;
    if (id == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await tripService.acceptAssignment(auth.accessToken, id);
      setState(() => _message = T.portal('portal.ride.accepted'));
    });
  }

  Future<void> _rejectAssignment() async {
    final id = _assignmentId;
    if (id == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await tripService.rejectAssignment(auth.accessToken, id);
      setState(() => _message = T.portal('portal.ride.rejected'));
    });
  }

  Future<void> _payNow() async {
    final id = _requestId;
    if (id == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await paymentService.createIntent(
        auth.accessToken,
        requestId: id,
        idempotencyKey: const Uuid().v4(),
      );
      setState(() => _message = T.portal('portal.ride.paymentStarted'));
    });
  }

  Future<void> _cancelRequest() async {
    final id = _requestId;
    if (id == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await tripService.cancelRequest(auth.accessToken, id);
      setState(() => _message = T.portal('portal.ride.cancelled'));
    });
  }

  Future<void> _advanceTrip() async {
    final tripId = _tripId;
    final next = _driverNextStatus;
    if (tripId == null || next == null) return;
    await _run(() async {
      final auth = useAuth(ref);
      await tripService.transitionTrip(auth.accessToken, tripId, next);
    });
  }

  Widget _messageBanner() {
    if (_message == null || _message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(_message!, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIncoming && _assignmentId != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(T.portal('portal.ride.incomingTitle'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(T.portal('portal.ride.incomingDesc')),
              if (_request != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${portalStr(_request?['pickup_address'])} → ${portalStr(_request?['dropoff_address'])}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              _messageBanner(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ShadButton(
                    onPressed: _busy ? null : _acceptAssignment,
                    child: Text(T.portal('portal.ride.accept')),
                  ),
                  ShadButton.outline(
                    onPressed: _busy ? null : _rejectAssignment,
                    child: Text(T.portal('portal.ride.reject')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_showRequesting && _requestId != null && _phase == 'pre_trip') {
      final status = portalStr(_request?['status'], 'pending');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(T.portal('portal.ride.requestingTitle'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(T.portal('portal.ride.requestingStatus', {'status': status})),
              _messageBanner(),
              const SizedBox(height: 12),
              if (status == 'awaiting_payment')
                ShadButton(
                  onPressed: _busy ? null : _payNow,
                  child: Text(T.portal('portal.ride.payNow')),
                ),
              ShadButton.ghost(
                onPressed: _busy ? null : _cancelRequest,
                child: Text(T.portal('portal.ride.cancelRequest')),
              ),
            ],
          ),
        ),
      );
    }

    if (_showDriving && (_tripId != null || _phase == 'awaiting_payment')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(T.portal('portal.ride.activeTitle'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_tripId != null) ...[
                Text(T.portal('portal.ride.tripStatus', {'status': _tripStatus ?? 'active'})),
                if (_trip != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${portalStr(_trip?['pickup_address'])} → ${portalStr(_trip?['dropoff_address'])}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (widget.area == PortalArea.driver && _driverNextStatus != null) ...[
                  const SizedBox(height: 12),
                  ShadButton(
                    onPressed: _busy ? null : _advanceTrip,
                    child: Text(T.portal('portal.ride.advance', {'status': _driverNextStatus!})),
                  ),
                ],
              ] else
                Text(T.portal('portal.ride.awaitingTrip')),
              _messageBanner(),
            ],
          ),
        ),
      );
    }

    if (!_showBooking) {
      return portalEmpty(T.portal('portal.ride.noActiveWorkflow'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(T.portal('portal.ride.bookTitle'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(T.portal('portal.ride.bookHint')),
            const SizedBox(height: 12),
            ShadInput(
              controller: _pickupController,
              placeholder: Text(T.portal('portal.ride.pickupPlaceholder')),
            ),
            const SizedBox(height: 8),
            ShadInput(
              controller: _dropoffController,
              placeholder: Text(T.portal('portal.ride.dropoffPlaceholder')),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () => setState(() {
                    _pickup = defaultMapCenter;
                    _pickupController.text = T.portal('portal.ride.setPickup');
                  }),
                  child: Text(T.portal('portal.ride.setPickup')),
                ),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () => setState(() {
                    _dropoff = const LatLng(45.515, -73.574);
                    _dropoffController.text = T.portal('portal.ride.setDropoff');
                  }),
                  child: Text(T.portal('portal.ride.setDropoff')),
                ),
              ],
            ),
            _messageBanner(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: (_pickup ?? widget.pickup) == null ||
                          (_dropoff ?? widget.dropoff) == null ||
                          _busy
                      ? null
                      : _estimateFare,
                  child: Text(T.portal('portal.ride.estimate')),
                ),
                ShadButton(
                  size: ShadButtonSize.sm,
                  onPressed: (_pickup ?? widget.pickup) == null ||
                          (_dropoff ?? widget.dropoff) == null ||
                          _busy
                      ? null
                      : _requestRide,
                  child: Text(T.portal('portal.ride.requestRide')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
