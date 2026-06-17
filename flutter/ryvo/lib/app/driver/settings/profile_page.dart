import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/panels/portal_driver_cars_panel.dart';
import 'package:ryvo/components/portal/panels/portal_profile_panel.dart';
import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/portal_tab_scaffold.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/i18n/t.dart';

class DriverProfilePage extends ConsumerWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.profile',
      expand: true,
      child: PortalTabScaffoldSimple(
        tabs: [
          T.portal('portal.nav.profile'),
          T.portal('portal.kyc.tabs.cars'),
        ],
        children: const [
          PortalProfilePanel(area: PortalArea.driver),
          PortalDriverCarsPanel(),
        ],
      ),
    );
  }
}
