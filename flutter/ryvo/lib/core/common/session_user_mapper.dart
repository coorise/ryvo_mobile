import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo/types/interfaces/schemas/session_user.dart';

Map<String, dynamic> jwtAppMetadata(String? accessToken) {
  if (accessToken == null || accessToken.isEmpty) return {};
  try {
    final parts = accessToken.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod == 2) {
      payload += '==';
    } else if (mod == 3) {
      payload += '=';
    }
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    final decoded = jsonDecode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
    return (decoded['app_metadata'] as Map<String, dynamic>?) ?? {};
  } catch (_) {
    return {};
  }
}

Object? _readMeta(User user, String key, Map<String, dynamic> jwtMeta) {
  return jwtMeta[key] ?? user.appMetadata[key] ?? user.userMetadata?[key];
}

SessionUser mapSupabaseUserToSession(User user, {String? accessToken}) {
  final jwtMeta = jwtAppMetadata(accessToken);
  final rolesRaw = _readMeta(user, 'roles', jwtMeta);
  final permissionsRaw = _readMeta(user, 'permissions', jwtMeta);

  final roles = rolesRaw is List
      ? rolesRaw.map((e) => e.toString()).toList()
      : rolesRaw is String
          ? [rolesRaw]
          : <String>[];
  final permissions = permissionsRaw is List
      ? permissionsRaw.map((e) => e.toString()).toList()
      : <String>[];

  final appRoleRaw = _readMeta(user, 'app_role', jwtMeta);
  final appRole = (appRoleRaw ?? (roles.isNotEmpty ? roles.first : null) ?? 'client').toString();
  final emailVerified =
      _readMeta(user, 'email_verified', jwtMeta) == true ||
      _readMeta(user, 'is_email_verified', jwtMeta) == true ||
      user.emailConfirmedAt != null;

  return SessionUser(
    id: user.id,
    email: user.email,
    roles: roles.isNotEmpty ? roles : [appRole],
    permissions: permissions,
    emailVerified: emailVerified,
    fullName: user.userMetadata?['full_name']?.toString(),
  );
}
