import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/vehicle/portal_vehicle_form.dart';

class DriverNewCarPage extends ConsumerWidget {
  const DriverNewCarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.kyc.addCar',
      subtitleKey: 'portal.kyc.addCarSubtitle',
      expand: true,
      child: const PortalVehicleForm(mode: 'create'),
    );
  }
}
