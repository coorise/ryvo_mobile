import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/vehicle/portal_vehicle_view.dart';

class DriverCarDetailPage extends ConsumerWidget {
  const DriverCarDetailPage({super.key, required this.carId});

  final String carId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.kyc.viewCar',
      subtitleKey: 'portal.kyc.viewCarSubtitle',
      expand: true,
      child: PortalVehicleView(vehicleId: carId),
    );
  }
}
