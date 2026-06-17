import 'package:flutter/material.dart';

import 'package:ryvo/i18n/t.dart';

class PortalPageShell extends StatelessWidget {
  const PortalPageShell({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    required this.child,
    this.expand = false,
  });

  final String titleKey;
  final String? subtitleKey;
  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            T.portal(titleKey),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitleKey != null) ...[
            const SizedBox(height: 6),
            Text(
              T.portal(subtitleKey!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );

    if (expand) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child)),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child),
        ],
      ),
    );
  }
}
