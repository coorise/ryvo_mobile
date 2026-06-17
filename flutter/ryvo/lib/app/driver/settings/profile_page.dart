import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_profile_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class DriverProfilePage extends ConsumerWidget {
  const DriverProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.profile',
      subtitleKey: null,
      expand: false,
      child: PortalProfilePanel(area: PortalArea.driver),
    );
  }
}
