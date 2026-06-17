import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/guards/abac.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';

class LandingHeroActions extends ConsumerWidget {
  const LandingHeroActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = useAuth(ref);
    final loggedIn = auth.isReady && Abac.isPortalUser(auth.user);
    final dashboardPath = Abac.portalDashboardPathForUser(auth.user);

    if (loggedIn) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          RyvoButton(
            onPressed: () => context.go(dashboardPath),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.layoutDashboard, size: 18),
                const SizedBox(width: 8),
                Text(T.nav('landing.goToDashboard')),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight, size: 16),
              ],
            ),
          ),
          RyvoButton(
            intent: RyvoButtonIntent.outline,
            onPressed: () => context.go(Routes.landing),
            child: Text(T.nav('landing.goHome')),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        RyvoButton(
          onPressed: () => context.go(Routes.authRegister),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.smartphone, size: 18),
              const SizedBox(width: 8),
              Text(T.nav('common.register')),
              const SizedBox(width: 4),
              const Icon(LucideIcons.arrowRight, size: 16),
            ],
          ),
        ),
        RyvoButton(
          intent: RyvoButtonIntent.outline,
          onPressed: () => context.go(Routes.authLogin),
          child: Text(T.nav('common.signIn')),
        ),
      ],
    );
  }
}
