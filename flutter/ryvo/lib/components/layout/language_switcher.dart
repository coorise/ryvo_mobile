import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/configs/const.dart';
import 'package:ryvo/stores/locale_store.dart';

/// Compact language pill — mirrors web `LanguageSwitcher`.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.compact = true});

  final bool compact;

  static const _labels = {
    'en': 'EN',
    'fr': 'FR',
    'es': 'ES',
    'zh': '中文',
    'de': 'DE',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final code = locale.languageCode;
    final label = _labels[code] ?? code.toUpperCase();
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.6);

    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: (value) => ref.read(localeProvider.notifier).setLanguage(value),
      itemBuilder: (context) => AppConst.supportedLanguages
          .map(
            (lng) => PopupMenuItem<String>(
              value: lng,
              child: Text(_labels[lng] ?? lng.toUpperCase()),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
