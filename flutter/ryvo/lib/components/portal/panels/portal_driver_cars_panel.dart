import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/kyc_const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/vehicle_profile.dart';
import 'package:ryvo/services/index.dart';

class PortalDriverCarsPanel extends ConsumerStatefulWidget {
  const PortalDriverCarsPanel({super.key});

  @override
  ConsumerState<PortalDriverCarsPanel> createState() => _PortalDriverCarsPanelState();
}

class _PortalDriverCarsPanelState extends ConsumerState<PortalDriverCarsPanel> {
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  List<Map<String, dynamic>> _vehicles = const [];

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
      final res = await vehiclesService.listMine(auth.accessToken);
      if (!mounted) return;
      setState(() {
        _vehicles = portalMapList(res, 'vehicles');
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

  Future<void> _deleteVehicle(String id) async {
    final auth = useAuth(ref);
    setState(() => _deleting = true);
    try {
      await vehiclesService.remove(auth.accessToken, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.kyc.carDeleted'))),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
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

  int _galleryCount(Map<String, dynamic> vehicle) {
    final keys = vehicle['image_keys'];
    if (keys is! List) return 0;
    return keys.length;
  }

  int _docCount(Map<String, dynamic> vehicle) {
    final docs = vehicle['documents'];
    return docs is List ? docs.length : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(T.portal('portal.kyc.carsHint'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            size: ShadButtonSize.sm,
            onPressed: () => context.go(Routes.driverKycCarsNew),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.plus, size: 14),
                const SizedBox(width: 6),
                Text(T.portal('portal.kyc.addCar')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_vehicles.isEmpty)
          portalEmpty(T.portal('portal.kyc.noCars'))
        else
          ..._vehicles.map((vehicle) {
            final id = portalStr(vehicle['id']);
            final status = portalStr(vehicle['status'], kycStatusPending);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.car, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${portalStr(vehicle['brand'])} ${portalStr(vehicle['name'])}'.trim(),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                portalStr(vehicle['plate']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(label: status.toUpperCase(), variant: _statusVariant(status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${T.portal('portal.kyc.galleryImages')}: ${_galleryCount(vehicle)}/$minGalleryImages+ · '
                      '${T.portal('portal.kyc.documentsSection')}: ${_docCount(vehicle)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          onPressed: id.isEmpty ? null : () => context.go('/driver/main/kyc/cars/$id'),
                          child: Text(T.portal('portal.kyc.viewCar')),
                        ),
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          onPressed: id.isEmpty ? null : () => context.go('/driver/main/kyc/cars/$id/edit'),
                          child: Text(T.portal('portal.kyc.editCar')),
                        ),
                        ShadButton.destructive(
                          size: ShadButtonSize.sm,
                          onPressed: _deleting || id.isEmpty ? null : () => _deleteVehicle(id),
                          child: const Icon(LucideIcons.trash2, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
