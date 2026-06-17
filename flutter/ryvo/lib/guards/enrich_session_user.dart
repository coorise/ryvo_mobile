import 'dart:async';

import 'package:ryvo/services/rbac_service.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

const _enrichTimeout = Duration(seconds: 12);

Future<SessionUser> enrichSessionUser(SessionUser user, String accessToken) async {
  try {
    final me = await RbacService()
        .getMe(accessToken)
        .timeout(_enrichTimeout, onTimeout: () => throw TimeoutException('rbac/me'));
    return SessionUser(
      id: user.id,
      email: user.email,
      roles: me.roles.isNotEmpty ? me.roles : user.roles,
      permissions: me.permissions.isNotEmpty ? me.permissions : user.permissions,
      emailVerified: user.emailVerified,
      fullName: user.fullName,
    );
  } catch (_) {
    return user;
  }
}

Future<AuthSession> enrichAuthSession(AuthSession session) async {
  final user = await enrichSessionUser(session.user, session.accessToken);
  return AuthSession(user: user, accessToken: session.accessToken);
}
