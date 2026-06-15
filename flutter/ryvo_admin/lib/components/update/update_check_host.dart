import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/configs/env.dart';
import 'package:ryvo_admin/services/github_release_service.dart';

/// Checks GitHub releases once per session on home/landing when [Env.checkGithubReleases].
class UpdateCheckHost extends StatefulWidget {
  const UpdateCheckHost({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateCheckHost> createState() => _UpdateCheckHostState();
}

class _UpdateCheckHostState extends State<UpdateCheckHost> {
  final _service = GithubReleaseService();
  var _checked = false;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked && Env.checkGithubReleases) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
    }
  }

  Future<void> _maybePrompt() async {
    if (!mounted || !Env.checkGithubReleases) return;
    try {
      final release = await _service.fetchLatestForApp();
      if (release == null || !mounted) return;

      final pkg = await _service.currentPackageInfo();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      if (!release.isNewerThan(pkg.version, currentBuild)) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getString(AppConst.storageIgnoredRelease) ?? '';
      if (ignored == release.tagName) return;

      if (!mounted) return;
      await _showDialog(release, pkg.version, currentBuild);
    } catch (_) {
      // Silent fail — OTA check must not block app usage.
    }
  }

  Future<void> _showDialog(
    GithubReleaseInfo release,
    String currentVersion,
    int currentBuild,
  ) async {
    final apk = release.apkAsset;
    if (apk == null) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A newer ${AppConst.appName} build is available on GitHub.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _VersionRow(label: 'Installed', version: currentVersion, build: currentBuild),
              const SizedBox(height: 8),
              _VersionRow(
                label: 'Available',
                version: release.version,
                build: release.buildNumber,
                highlight: true,
              ),
              const SizedBox(height: 8),
              Text('Release tag: ${release.tagName}', style: Theme.of(context).textTheme.bodySmall),
              if (release.name.isNotEmpty && release.name != release.tagName) ...[
                const SizedBox(height: 4),
                Text(release.name, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (release.body.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Release notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(release.body.trim()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'ignore'),
            child: const Text('Ignore'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'download'),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'ignore') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConst.storageIgnoredRelease, release.tagName);
      return;
    }

    if (action != 'download') return;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
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
      if (mounted) Navigator.pop(context);
      await _service.installDownloadedApk(file);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.version,
    required this.build,
    this.highlight = false,
  });

  final String label;
  final String version;
  final int build;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          color: highlight ? Theme.of(context).colorScheme.primary : null,
        );
    return Text('$label: v$version (build $build)', style: style);
  }
}
