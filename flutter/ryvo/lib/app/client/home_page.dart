import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/components/portal/portal_home_cards.dart';
import 'package:ryvo/components/portal/portal_page_header.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/i18n/t.dart';

class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageHeader(
      title: T.portal('portal.nav.overview'),
      subtitle: T.portal('portal.home.client.subtitle'),
      child: PortalHomeCards(
        cards: [
          PortalHomeCard(
            title: T.portal('portal.home.client.liveMapTitle'),
            description: T.portal('portal.home.client.liveMapDesc'),
            href: Routes.clientLiveMap,
            icon: LucideIcons.map,
          ),
          PortalHomeCard(
            title: T.portal('portal.nav.rides'),
            description: T.portal('portal.rides.subtitle'),
            href: Routes.clientRides,
            icon: LucideIcons.car,
          ),
          PortalHomeCard(
            title: T.portal('portal.nav.drivers'),
            description: T.portal('portal.drivers.subtitle'),
            href: Routes.clientDrivers,
            icon: LucideIcons.user,
          ),
        ],
      ),
    );
  }
}
