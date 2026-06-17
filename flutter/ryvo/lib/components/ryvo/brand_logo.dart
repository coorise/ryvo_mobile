import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo/configs/const.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.subtitle = 'MOBILITY', this.href});

  final String subtitle;
  final String? href;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/app_icon.svg',
          width: 40,
          height: 40,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConst.appName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );

    if (href == null) return logo;
    return InkWell(
      onTap: () => context.go(href!),
      borderRadius: BorderRadius.circular(12),
      child: logo,
    );
  }
}
