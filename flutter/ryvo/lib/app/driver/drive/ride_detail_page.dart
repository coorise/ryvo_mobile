import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/panels/portal_ride_detail_panel.dart';
import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/configs/portal_nav.dart';

class DriverRideDetailPage extends ConsumerWidget {
  const DriverRideDetailPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.rides.detailTitle',
      expand: false,
      child: PortalRideDetailPanel(area: PortalArea.driver, tripId: tripId),
    );
  }
}
