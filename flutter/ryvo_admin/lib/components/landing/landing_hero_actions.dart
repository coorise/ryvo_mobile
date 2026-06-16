import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryvo_admin/components/ryvo/ryvo_button.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';

class LandingHeroActions extends ConsumerWidget {
  const LandingHeroActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = useAuth(ref);
    final loggedIn = auth.isReady && auth.user != null;
    final dashboardPath = Abac.dashboardPathForUser(auth.user);

    if (loggedIn) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          RyvoButton(
            onPressed: () => context.go(dashboardPath),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.layoutDashboard, size: 18),
                SizedBox(width: 8),
                Text('Go to dashboard'),
                SizedBox(width: 4),
                Icon(LucideIcons.arrowRight, size: 16),
              ],
            ),
          ),
          RyvoButton(
            intent: RyvoButtonIntent.outline,
            onPressed: () => context.go(Routes.landing),
            child: const Text('Go home'),
          ),
        ],
      );
    }

    return RyvoButton(
      onPressed: () => context.go(Routes.authLogin),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Staff sign in'),
          SizedBox(width: 4),
          Icon(LucideIcons.arrowRight, size: 16),
        ],
      ),
    );
  }
}
