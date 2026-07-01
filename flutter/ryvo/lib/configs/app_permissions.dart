import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'package:ryvo/configs/portal_nav.dart';

/// Declarative permission groups for the client/driver app (Uber-like).
class AppPermissionSpec {
  const AppPermissionSpec({
    required this.id,
    required this.permission,
    required this.titleKey,
    required this.descriptionKey,
    this.androidOnly = false,
    this.iosOnly = false,
    this.driverOnly = false,
  });

  final String id;
  final Permission permission;
  final String titleKey;
  final String descriptionKey;
  final bool androidOnly;
  final bool iosOnly;
  final bool driverOnly;
}

const _clientPermissions = <AppPermissionSpec>[
  AppPermissionSpec(
    id: 'location',
    permission: Permission.locationWhenInUse,
    titleKey: 'permissions.location.title',
    descriptionKey: 'permissions.location.description',
  ),
  AppPermissionSpec(
    id: 'location_always',
    permission: Permission.locationAlways,
    titleKey: 'permissions.locationAlways.title',
    descriptionKey: 'permissions.locationAlways.description',
  ),
  AppPermissionSpec(
    id: 'sms',
    permission: Permission.sms,
    titleKey: 'permissions.sms.title',
    descriptionKey: 'permissions.sms.description',
    androidOnly: true,
  ),
  AppPermissionSpec(
    id: 'camera',
    permission: Permission.camera,
    titleKey: 'permissions.camera.title',
    descriptionKey: 'permissions.camera.description',
  ),
  AppPermissionSpec(
    id: 'photos',
    permission: Permission.photos,
    titleKey: 'permissions.photos.title',
    descriptionKey: 'permissions.photos.description',
  ),
  AppPermissionSpec(
    id: 'notifications',
    permission: Permission.notification,
    titleKey: 'permissions.notifications.title',
    descriptionKey: 'permissions.notifications.description',
  ),
  AppPermissionSpec(
    id: 'notification_policy',
    permission: Permission.accessNotificationPolicy,
    titleKey: 'permissions.notificationPolicy.title',
    descriptionKey: 'permissions.notificationPolicy.description',
    androidOnly: true,
  ),
  AppPermissionSpec(
    id: 'exact_alarm',
    permission: Permission.scheduleExactAlarm,
    titleKey: 'permissions.exactAlarm.title',
    descriptionKey: 'permissions.exactAlarm.description',
    androidOnly: true,
  ),
  AppPermissionSpec(
    id: 'activity',
    permission: Permission.activityRecognition,
    titleKey: 'permissions.activity.title',
    descriptionKey: 'permissions.activity.description',
    androidOnly: true,
    driverOnly: true,
  ),
  AppPermissionSpec(
    id: 'battery',
    permission: Permission.ignoreBatteryOptimizations,
    titleKey: 'permissions.battery.title',
    descriptionKey: 'permissions.battery.description',
    androidOnly: true,
    driverOnly: true,
  ),
  AppPermissionSpec(
    id: 'install',
    permission: Permission.requestInstallPackages,
    titleKey: 'permissions.install.title',
    descriptionKey: 'permissions.install.description',
    androidOnly: true,
  ),
];

List<AppPermissionSpec> permissionsForArea(PortalArea area) {
  return _clientPermissions.where((spec) {
    if (spec.androidOnly && !Platform.isAndroid) return false;
    if (spec.iosOnly && !Platform.isIOS) return false;
    if (spec.driverOnly && area != PortalArea.driver) return false;
    return true;
  }).toList();
}

/// Bump when adding new required permissions so the prompt can reappear.
const appPermissionsVersion = 2;
