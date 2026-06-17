import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/kyc_const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/storage_keys.dart';
import 'package:ryvo/lib/vehicle_profile.dart';
import 'package:ryvo/services/index.dart';

class PortalVehicleView extends ConsumerStatefulWidget {
  const PortalVehicleView({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<PortalVehicleView> createState() => _PortalVehicleViewState();
}

class _PortalVehicleViewState extends ConsumerState<PortalVehicleView> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _vehicle;

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
      final res = await vehiclesService.getVehicle(auth.accessToken, widget.vehicleId);
      if (!mounted) return;
      final vehicle = res['vehicle'];
      setState(() {
        _vehicle = vehicle is Map ? Map<String, dynamic>.from(vehicle) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.kyc.unavailable');
        _loading = false;
      });
    }
  }

  StatusBadgeVariant _statusVariant(String status) {
    switch (status) {
      case kycStatusApproved:
        return StatusBadgeVariant.success;
      case kycStatusRejected:
        return StatusBadgeVariant.danger;
      default:
        return StatusBadgeVariant.warning;
    }
  }

  String _energyLabel(String? value) {
    if (value == null || value.isEmpty) return '—';
    return T.portal('portal.kyc.energy.$value');
  }

  String _tyresLabel(String? value) {
    if (value == null || value.isEmpty) return '—';
    final key = 'portal.kyc.tyres.$value';
    final translated = T.portal(key);
    return translated == key ? value : translated;
  }

  String _docLabel(Map<String, dynamic> doc) {
    final docType = portalStr(doc['doc_type']);
    if (docType == 'other' && portalStr(doc['label']).isNotEmpty) return portalStr(doc['label']);
    if (docType == 'registration') return T.portal('portal.kyc.registration');
    if (docType == 'insurance') return T.portal('portal.kyc.insurance');
    return docType;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);
    final vehicle = _vehicle;
    if (vehicle == null) return portalEmpty(T.nav('common.noData'));

    final status = portalStr(vehicle['status'], kycStatusPending);
    final imageKeys = vehicle['image_keys'];
    final galleryCount = imageKeys is List ? imageKeys.length : 0;
    final documents = vehicle['documents'];
    final docs = documents is List
        ? documents.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false)
        : const <Map<String, dynamic>>[];

    final specs = [
      (T.portal('portal.kyc.fields.brand'), portalStr(vehicle['brand'], '—')),
      (T.portal('portal.kyc.fields.name'), portalStr(vehicle['name'], '—')),
      (T.portal('portal.kyc.fields.plate'), portalStr(vehicle['plate'], '—')),
      (T.portal('portal.kyc.fields.energy'), _energyLabel(vehicle['energy_type']?.toString())),
      (T.portal('portal.kyc.fields.tyres'), _tyresLabel(vehicle['tyres_type']?.toString())),
      (
        T.portal('portal.kyc.fields.speed'),
        vehicle['max_speed_kmh'] != null ? '${vehicle['max_speed_kmh']} km/h' : '—',
      ),
      (
        T.portal('portal.kyc.fields.age'),
        vehicle['age_years'] != null ? '${vehicle['age_years']} y' : '—',
      ),
      (
        T.portal('portal.kyc.fields.carbon'),
        vehicle['carbon_print'] != null ? '${vehicle['carbon_print']} g/km' : '—',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Icon(LucideIcons.car, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${portalStr(vehicle['brand'])} ${portalStr(vehicle['name'])}'.trim(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(portalStr(vehicle['plate']), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusBadge(label: status.toUpperCase(), variant: _statusVariant(status)),
          ],
        ),
        if (portalStr(vehicle['rejection_reason']).isNotEmpty && status == kycStatusRejected) ...[
          const SizedBox(height: 8),
          Text(
            portalStr(vehicle['rejection_reason']),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specs
              .map(
                (row) => SizedBox(
                  width: 160,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.$1, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(row.$2, style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(T.portal('portal.kyc.mediaSection'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('${T.portal('portal.kyc.banner')}: ${isRealStorageKey(vehicle['banner_key']?.toString()) ? '✓' : '—'}'),
                Text('${T.portal('portal.kyc.galleryImages')}: $galleryCount / $minGalleryImages+'),
                Text('${T.portal('portal.kyc.videoOptional')}: ${isRealStorageKey(vehicle['video_key']?.toString()) ? '✓' : '—'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(T.portal('portal.kyc.documentsSection'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  Text(T.portal('portal.kyc.noDocs'), style: Theme.of(context).textTheme.bodySmall)
                else
                  ...docs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${_docLabel(doc)} · ${portalStr(doc['status'], kycStatusPending)}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ShadButton(
              onPressed: () => context.go('/driver/main/kyc/cars/${widget.vehicleId}/edit'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.pencil, size: 14),
                  const SizedBox(width: 6),
                  Text(T.portal('portal.kyc.editCar')),
                ],
              ),
            ),
            ShadButton.outline(
              onPressed: () => context.go('/driver/main/kyc?tab=cars'),
              child: Text(T.portal('portal.kyc.backToCars')),
            ),
          ],
        ),
      ],
    );
  }
}
