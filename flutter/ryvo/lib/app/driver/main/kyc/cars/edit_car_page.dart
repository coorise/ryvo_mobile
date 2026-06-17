import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/vehicle/portal_vehicle_form.dart';

class DriverEditCarPage extends ConsumerWidget {
  const DriverEditCarPage({super.key, required this.carId});

  final String carId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.kyc.editCar',
      subtitleKey: 'portal.kyc.editCarSubtitle',
      expand: true,
      child: PortalVehicleForm(mode: 'edit', vehicleId: carId),
    );
  }
}
