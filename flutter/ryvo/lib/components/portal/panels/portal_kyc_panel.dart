import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/panels/portal_driver_cars_panel.dart';
import 'package:ryvo/components/portal/panels/portal_kyc_you_tab.dart';
import 'package:ryvo/components/portal/portal_tab_scaffold.dart';
import 'package:ryvo/i18n/t.dart';

class PortalKycPanel extends ConsumerWidget {
  const PortalKycPanel({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalTabScaffoldSimple(
      initialIndex: initialTab,
      tabs: [
        T.portal('portal.kyc.tabs.you'),
        T.portal('portal.kyc.tabs.cars'),
      ],
      children: const [
        PortalKycYouTab(),
        Padding(
          padding: EdgeInsets.all(12),
          child: PortalDriverCarsPanel(),
        ),
      ],
    );
  }
}
