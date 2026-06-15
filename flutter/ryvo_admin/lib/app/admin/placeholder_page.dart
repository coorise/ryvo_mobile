import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Placeholder for admin screens not yet ported from web.
class AdminPlaceholderPage extends StatelessWidget {
  const AdminPlaceholderPage({super.key, required this.title, this.webPath});

  final String title;
  final String? webPath;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'This screen mirrors the web admin module. Port UI from '
                'client/web/ryvo_admin/src/app/admin${webPath ?? ''} into '
                'lib/app/admin${webPath ?? ''}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
