import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/configs/landing_const.dart';

class LandingCityGrid extends StatelessWidget {
  const LandingCityGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final totalDrivers = LandingConst.totalDrivers;
    final driverFmt = NumberFormat.decimalPattern();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CANADIAN PRESENCE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${LandingConst.landingCities.length} cities · ${driverFmt.format(totalDrivers)}+ drivers',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1024
                      ? 4
                      : constraints.maxWidth >= 768
                          ? 3
                          : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: LandingConst.landingCities.length,
                    itemBuilder: (context, index) => _CityCard(city: LandingConst.landingCities[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city});

  final LandingCity city;

  @override
  Widget build(BuildContext context) {
    final driverFmt = NumberFormat.decimalPattern();
    final isLive = city.status == 'live';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: city.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => CachedNetworkImage(
              imageUrl: LandingConst.fallbackCityImage,
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: ShadBadge(
              child: Text(isLive ? 'Live' : 'Soon'),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(city.province, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 4),
                    Text(
                      '${driverFmt.format(city.drivers)} drivers',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
