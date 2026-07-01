import 'package:permission_handler/permission_handler.dart';

import 'package:ryvo/configs/app_permissions.dart';

class PermissionService {
  PermissionService._();

  static Future<PermissionStatus> statusFor(AppPermissionSpec spec) {
    return spec.permission.status;
  }

  static Future<Map<String, PermissionStatus>> statusesFor(
    Iterable<AppPermissionSpec> specs,
  ) async {
    final entries = await Future.wait(
      specs.map((spec) async => MapEntry(spec.id, await spec.permission.status)),
    );
    return Map.fromEntries(entries);
  }

  static bool isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  static bool needsPrompt(PermissionStatus status) {
    return !isGranted(status) && status != PermissionStatus.restricted;
  }

  static Future<PermissionStatus> request(AppPermissionSpec spec) async {
    if (spec.id == 'location_always') {
      final whenInUse = await Permission.locationWhenInUse.status;
      if (!isGranted(whenInUse)) {
        final foreground = await Permission.locationWhenInUse.request();
        if (!isGranted(foreground)) return foreground;
      }
    }
    return spec.permission.request();
  }

  static Future<void> openSettings() => openAppSettings();
}
