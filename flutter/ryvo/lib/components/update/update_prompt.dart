import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo/components/update/app_update.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/services/github_release_service.dart';

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
      if (!AppUpdate.isNewerRelease(release, pkg)) return;

      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getString(AppConst.storageIgnoredRelease) ?? '';
      if (ignored == release.tagName) return;

      if (!context.mounted) return;
      await _showDialog(context, release, pkg.version, int.tryParse(pkg.buildNumber) ?? 0);
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
    if (release.apkAsset == null) return;

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
              Text('Installed: v$currentVersion (build $currentBuild)'),
              const SizedBox(height: 8),
              Text(
                'Available: v${release.version} (build ${release.buildNumber})',
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary),
              ),
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
