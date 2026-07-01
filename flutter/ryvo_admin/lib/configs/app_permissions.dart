import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Declarative permission groups for the admin operations app.
class AppPermissionSpec {
  const AppPermissionSpec({
    required this.id,
    required this.permission,
    required this.titleKey,
    required this.descriptionKey,
    this.androidOnly = false,
    this.iosOnly = false,
  });

  final String id;
  final Permission permission;
  final String titleKey;
  final String descriptionKey;
  final bool androidOnly;
  final bool iosOnly;
}

const adminPermissions = <AppPermissionSpec>[
  AppPermissionSpec(
    id: 'location',
    permission: Permission.locationWhenInUse,
    titleKey: 'permissions.location.title',
    descriptionKey: 'permissions.location.adminDescription',
  ),
  AppPermissionSpec(
    id: 'camera',
    permission: Permission.camera,
    titleKey: 'permissions.camera.title',
    descriptionKey: 'permissions.camera.adminDescription',
  ),
  AppPermissionSpec(
    id: 'photos',
    permission: Permission.photos,
    titleKey: 'permissions.photos.title',
    descriptionKey: 'permissions.photos.adminDescription',
  ),
  AppPermissionSpec(
    id: 'notifications',
    permission: Permission.notification,
    titleKey: 'permissions.notifications.title',
    descriptionKey: 'permissions.notifications.adminDescription',
  ),
  AppPermissionSpec(
    id: 'sms',
    permission: Permission.sms,
    titleKey: 'permissions.sms.title',
    descriptionKey: 'permissions.sms.adminDescription',
    androidOnly: true,
  ),
  AppPermissionSpec(
    id: 'install',
    permission: Permission.requestInstallPackages,
    titleKey: 'permissions.install.title',
    descriptionKey: 'permissions.install.adminDescription',
    androidOnly: true,
  ),
];

List<AppPermissionSpec> permissionsForAdmin() {
  return adminPermissions.where((spec) {
    if (spec.androidOnly && !Platform.isAndroid) return false;
    if (spec.iosOnly && !Platform.isIOS) return false;
    return true;
  }).toList();
}

const appPermissionsVersion = 2;
