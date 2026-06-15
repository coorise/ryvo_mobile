import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/configs/env.dart';
import 'package:ryvo_admin/services/github_release_service.dart';

/// Prompts for a GitHub release update when a newer dev/prod APK exists.
class UpdatePrompt {
  UpdatePrompt._();

  static final _service = GithubReleaseService();
  static var _checkedThisSession = false;

  static Future<bool> _otaEnabled() async {
    if (Env.checkGithubReleases) return true;
    final pkg = await PackageInfo.fromPlatform();
    if (pkg.packageName.endsWith('.local')) return false;
    return pkg.packageName.endsWith('.dev') || pkg.packageName == 'com.ryvo.admin';
  }

  static Future<void> maybeShow(BuildContext context) async {
    if (_checkedThisSession) return;
    if (!await _otaEnabled()) return;
    _checkedThisSession = true;

    try {
      final release = await _service.fetchLatestForApp();
      if (release == null || !context.mounted) return;

      final pkg = await _service.currentPackageInfo();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      if (!release.isNewerThan(pkg.version, currentBuild)) return;

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

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Downloading update…')),
          ],
        ),
      ),
    );

    try {
      final file = await _service.downloadApk(apk);
      if (context.mounted) Navigator.pop(context);
      await _service.installDownloadedApk(file);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
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
