import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ryvo_admin/configs/env.dart';

class GithubReleaseAsset {
  const GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  final String name;
  final String downloadUrl;
  final int size;

  factory GithubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GithubReleaseAsset(
      name: json['name']?.toString() ?? '',
      downloadUrl: json['browser_download_url']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class GithubReleaseInfo {
  const GithubReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.version,
    required this.buildNumber,
    required this.apkAsset,
  });

  final String tagName;
  final String name;
  final String body;
  final String version;
  final int buildNumber;
  final GithubReleaseAsset? apkAsset;

  bool isNewerThan(String currentVersion, int currentBuild) {
    final cmp = _compareSemver(version, currentVersion);
    if (cmp > 0) return true;
    if (cmp < 0) return false;
    return buildNumber > currentBuild;
  }

  static int _compareSemver(String a, String b) {
    final pa = a.split('.').map(int.tryParse).toList();
    final pb = b.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? (pa[i] ?? 0) : 0;
      final vb = i < pb.length ? (pb[i] ?? 0) : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }
}

class GithubReleaseService {
  GithubReleaseService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PackageInfo> currentPackageInfo() => PackageInfo.fromPlatform();

  Future<GithubReleaseInfo?> fetchLatestForApp() async {
    if (!Env.checkGithubReleases) return null;

    final uri = Uri.parse(
      'https://api.github.com/repos/${Env.githubRepo}/releases?per_page=20',
    );
    final res = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Ryvo-Mobile-Updater',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('GitHub releases HTTP ${res.statusCode}');
    }

    final rows = jsonDecode(res.body);
    if (rows is! List) return null;

    final prefix = Env.releaseTagPrefix();
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final tag = map['tag_name']?.toString() ?? '';
      if (!tag.startsWith(prefix)) continue;

      final parsed = _parseTag(tag, prefix);
      if (parsed == null) continue;

      GithubReleaseAsset? apk;
      final assets = map['assets'];
      if (assets is List) {
        for (final a in assets) {
          if (a is! Map) continue;
          final asset = GithubReleaseAsset.fromJson(Map<String, dynamic>.from(a));
          if (asset.name.endsWith('.apk')) {
            apk = asset;
            break;
          }
        }
      }

      return GithubReleaseInfo(
        tagName: tag,
        name: map['name']?.toString() ?? tag,
        body: map['body']?.toString() ?? '',
        version: parsed.$1,
        buildNumber: parsed.$2,
        apkAsset: apk,
      );
    }
    return null;
  }

  (String, int)? _parseTag(String tag, String prefix) {
    // CI tags use 1.0.0-2; pub semver uses 1.0.0+2.
    final rest = tag.substring(prefix.length);
    final match = RegExp(r'^([\d.]+)(?:[+\-](\d+))?$').firstMatch(rest);
    if (match == null) return null;
    final version = match.group(1)!;
    final build = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (version.isEmpty) return null;
    return (version, build);
  }

  Future<File> downloadApk(GithubReleaseAsset asset) async {
    final res = await _client.get(Uri.parse(asset.downloadUrl));
    if (res.statusCode != 200) {
      throw Exception('Download failed (${res.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final safeName = asset.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  Future<void> installDownloadedApk(File file) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('In-app install is supported on Android only.');
    }
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  void dispose() => _client.close();
}
