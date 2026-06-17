import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/i18n/t.dart';

class PortalHomeCard {
  const PortalHomeCard({
    required this.title,
    required this.description,
    required this.href,
    required this.icon,
  });

  final String title;
  final String description;
  final String href;
  final IconData icon;
}

class PortalHomeCards extends StatelessWidget {
  const PortalHomeCards({super.key, required this.cards});

  final List<PortalHomeCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            final primary = Theme.of(context).colorScheme.primary;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(card.icon, size: 20, color: primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(card.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      card.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    RyvoButton(
                      size: ShadButtonSize.sm,
                      onPressed: () => context.go(card.href),
                      child: Text(T.portal('portal.home.open')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
