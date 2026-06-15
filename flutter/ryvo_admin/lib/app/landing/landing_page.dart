import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/landing/landing_city_grid.dart';
import 'package:ryvo_admin/components/landing/landing_hero_actions.dart';
import 'package:ryvo_admin/components/layout/site_header.dart';
import 'package:ryvo_admin/components/ryvo/ryvo_button.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/configs/landing_const.dart';
import 'package:ryvo_admin/core/common/view_insets.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{
    for (final link in LandingConst.navLinks) link.sectionId: GlobalKey(),
  };

  void _scrollToSection(String sectionId) {
    final key = _sectionKeys[sectionId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  IconData _featureIcon(String name) => switch (name) {
        'shield_check' => LucideIcons.shieldCheck,
        'badge_dollar' => LucideIcons.badgeDollarSign,
        _ => LucideIcons.zap,
      };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              primary: false,
              automaticallyImplyLeading: false,
              toolbarHeight: ViewInsets.toolbarHeight + 1,
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: SiteHeader(onNavTap: _scrollToSection),
            ),
          SliverToBoxAdapter(
            child: _Section(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1024;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 7, child: _HeroCopy(primary: primary)),
                                  const SizedBox(width: 48),
                                  Expanded(flex: 5, child: _RideCard(primary: primary)),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _HeroCopy(primary: primary),
                                  const SizedBox(height: 32),
                                  _RideCard(primary: primary),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _sectionKeys['features'],
              child: _Section(
                topBorder: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHY RYVO-LINE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth >= 1024
                                  ? 3
                                  : constraints.maxWidth >= 640
                                      ? 2
                                      : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: cols == 1 ? 1.6 : 0.95,
                                ),
                                itemCount: LandingConst.features.length,
                                itemBuilder: (context, index) {
                                  final feature = LandingConst.features[index];
                                  return ShadCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(_featureIcon(feature.iconName), color: primary),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(feature.title, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 8),
                                          Text(
                                            feature.description,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _sectionKeys['cities'],
              child: const LandingCityGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _sectionKeys['safety'],
              child: _Section(
                topBorder: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAFETY',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Built for peace of mind',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth >= 768 ? 3 : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: cols == 1 ? 1.8 : 1.1,
                                ),
                                itemCount: LandingConst.safetyPoints.length,
                                itemBuilder: (context, index) {
                                  final item = LandingConst.safetyPoints[index];
                                  return ShadCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.description,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _sectionKeys['drivers'],
              child: _Section(
                topBorder: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final copy = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BECOME A DRIVER',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Drive. Earn. On your terms.',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Flexible hours, transparent earnings, and fast KYC onboarding.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          );
                          final cta = RyvoButton(
                            intent: RyvoButtonIntent.signIn,
                            onPressed: () => context.go(Routes.authLogin),
                            child: const Text('Staff sign in'),
                          );

                          if (constraints.maxWidth >= 640) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: copy),
                                const SizedBox(width: 24),
                                cta,
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              copy,
                              const SizedBox(height: 24),
                              cta,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              topBorder: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        '© ${DateTime.now().year} Ryvo-Line · Montréal, QC',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () => context.go(Routes.legalTos),
                            child: const Text('Terms'),
                          ),
                          TextButton(
                            onPressed: () => context.go(Routes.legalPrivacy),
                            child: const Text('Privacy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'New · Montréal launch',
                style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, height: 1.05),
            children: [
              const TextSpan(text: 'Urban mobility,\n'),
              TextSpan(text: 'reimagined.', style: TextStyle(color: primary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConst.appTagline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        const LandingHeroActions(),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ride in 3 taps', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Destination → vehicle → pay. Nothing extra.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text('• Real-time driver location', style: _bulletStyle(context)),
            Text('• Secure payments after driver accepts', style: _bulletStyle(context)),
            Text('• In-trip chat with your driver', style: _bulletStyle(context)),
          ],
        ),
      ),
    );
  }

  TextStyle? _bulletStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.topBorder = false});

  final Widget child;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: topBorder ? Border(top: BorderSide(color: Theme.of(context).dividerColor)) : null,
      ),
      child: child,
    );
  }
}
