import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ryvo/configs/env.dart';
import 'package:ryvo/services/github_release_service.dart';

class AppUpdate {
  AppUpdate._();

  static final _service = GithubReleaseService();

  static Future<bool> otaEnabled() async {
    if (Env.checkGithubReleases) return true;
    final pkg = await PackageInfo.fromPlatform();
    if (pkg.packageName.endsWith('.local')) return false;
    return pkg.packageName.endsWith('.dev') || pkg.packageName == 'com.ryvo.client';
  }

  static Future<PackageInfo> currentPackageInfo() => _service.currentPackageInfo();

  static Future<GithubReleaseInfo?> fetchLatestRelease() async {
    if (!await otaEnabled()) return null;
    return _service.fetchLatestForApp();
  }

  static bool isNewerRelease(GithubReleaseInfo release, PackageInfo pkg) {
    final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
    return release.isNewerThan(pkg.version, currentBuild);
  }

  static String deployLabel(PackageInfo pkg) {
    if (pkg.packageName.endsWith('.local')) return 'local';
    if (pkg.packageName.endsWith('.dev')) return 'dev';
    if (pkg.packageName == 'com.ryvo.client') return 'prod';
    return pkg.packageName;
  }

  static Future<void> downloadAndInstall(BuildContext context, GithubReleaseInfo release) async {
    final apk = release.apkAsset;
    if (apk == null) {
      throw Exception('No APK attached to this release.');
    }
    if (!Platform.isAndroid) {
      throw UnsupportedError('In-app install is supported on Android only.');
    }

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
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      rethrow;
    }
  }
}
