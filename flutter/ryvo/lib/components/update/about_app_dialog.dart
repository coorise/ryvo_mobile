import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ryvo/components/update/app_update.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/services/github_release_service.dart';

Future<void> showAboutAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const AboutAppDialog(),
  );
}

class AboutAppDialog extends StatefulWidget {
  const AboutAppDialog({super.key});

  @override
  State<AboutAppDialog> createState() => _AboutAppDialogState();
}

class _AboutAppDialogState extends State<AboutAppDialog> {
  PackageInfo? _pkg;
  var _loadingInfo = true;
  var _checking = false;
  GithubReleaseInfo? _latest;
  String? _checkMessage;
  String? _checkError;
  var _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final pkg = await AppUpdate.currentPackageInfo();
      if (!mounted) return;
      setState(() {
        _pkg = pkg;
        _loadingInfo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInfo = false;
        _checkError = e.toString();
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checking = true;
      _checkMessage = null;
      _checkError = null;
      _latest = null;
      _updateAvailable = false;
    });

    try {
      if (!await AppUpdate.otaEnabled()) {
        if (!mounted) return;
        setState(() {
          _checking = false;
          _checkMessage = 'Update checks are disabled for local builds.';
        });
        return;
      }

      final pkg = _pkg ?? await AppUpdate.currentPackageInfo();
      final latest = await AppUpdate.fetchLatestRelease();
      if (!mounted) return;

      if (latest == null) {
        setState(() {
          _checking = false;
          _checkMessage = 'No matching release found on GitHub.';
        });
        return;
      }

      final hasUpdate = AppUpdate.isNewerRelease(latest, pkg);
      setState(() {
        _checking = false;
        _latest = latest;
        _updateAvailable = hasUpdate;
        _checkMessage = hasUpdate ? 'A newer build is available.' : 'You are on the latest release.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _checkError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _downloadUpdate() async {
    final release = _latest;
    if (release == null || !mounted) return;
    try {
      await AppUpdate.downloadAndInstall(context, release);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = _pkg;
    final build = pkg == null ? 0 : int.tryParse(pkg.buildNumber) ?? 0;

    return AlertDialog(
      title: Text('About ${AppConst.appName}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingInfo)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pkg != null) ...[
              Text('Version: v${pkg.version} (build $build)'),
              const SizedBox(height: 8),
              Text('Package: ${pkg.packageName}'),
              const SizedBox(height: 8),
              Text('Environment: ${AppUpdate.deployLabel(pkg)}'),
            ],
            if (_checking) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Checking for updates…')),
                ],
              ),
            ],
            if (_checkMessage != null) ...[
              const SizedBox(height: 16),
              Text(_checkMessage!),
            ],
            if (_checkError != null) ...[
              const SizedBox(height: 16),
              Text(_checkError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_updateAvailable && _latest != null)
          FilledButton(
            onPressed: _checking ? null : _downloadUpdate,
            child: const Text('Download'),
          )
        else
          FilledButton(
            onPressed: _checking ? null : _checkForUpdates,
            child: const Text('Check for updates'),
          ),
      ],
    );
  }
}
