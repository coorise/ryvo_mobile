import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_rides_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class DriverRidesPage extends ConsumerWidget {
  const DriverRidesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.rides',
      subtitleKey: 'portal.rides.subtitle',
      expand: false,
      child: PortalRidesPanel(area: PortalArea.driver),
    );
  }
}
