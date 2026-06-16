import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/components/update/app_update.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/services/github_release_service.dart';

/// Prompts for a GitHub release update when a newer dev/prod APK exists.
class UpdatePrompt {
  UpdatePrompt._();

  static var _checkedThisSession = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_checkedThisSession) return;
    if (!await AppUpdate.otaEnabled()) return;
    _checkedThisSession = true;

    try {
      final release = await AppUpdate.fetchLatestRelease();
      if (release == null || !context.mounted) return;

      final pkg = await AppUpdate.currentPackageInfo();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      if (!AppUpdate.isNewerRelease(release, pkg)) return;

      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getString(AppConst.storageIgnoredRelease) ?? '';
      if (ignored == release.tagName) return;

      if (!context.mounted) return;
      await _showDialog(context, release, pkg.version, currentBuild);
    } catch (e, st) {
      debugPrint('OTA check failed: $e\n$st');
    }
  }

  static Future<void> _showDialog(
    BuildContext context,
    GithubReleaseInfo release,
    String currentVersion,
    int currentBuild,
  ) async {
    final apk = release.apkAsset;
    if (apk == null) return;

    final action = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A newer ${AppConst.appName} build is available on GitHub.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _VersionRow(label: 'Installed', version: currentVersion, buildNumber: currentBuild),
              const SizedBox(height: 8),
              _VersionRow(
                label: 'Available',
                version: release.version,
                buildNumber: release.buildNumber,
                highlight: true,
              ),
              const SizedBox(height: 8),
              Text('Release tag: ${release.tagName}', style: Theme.of(dialogContext).textTheme.bodySmall),
              if (release.name.isNotEmpty && release.name != release.tagName) ...[
                const SizedBox(height: 4),
                Text(release.name, style: Theme.of(dialogContext).textTheme.bodySmall),
              ],
              if (release.body.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Release notes', style: Theme.of(dialogContext).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(release.body.trim()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'ignore'),
            child: const Text('Ignore'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'download'),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (action == 'ignore') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConst.storageIgnoredRelease, release.tagName);
      return;
    }

    if (action != 'download') return;
    if (!context.mounted) return;

    try {
      await AppUpdate.downloadAndInstall(context, release);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.version,
    required this.buildNumber,
    this.highlight = false,
  });

  final String label;
  final String version;
  final int buildNumber;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          color: highlight ? Theme.of(context).colorScheme.primary : null,
        );
    return Text('$label: v$version (build $buildNumber)', style: style);
  }
}
