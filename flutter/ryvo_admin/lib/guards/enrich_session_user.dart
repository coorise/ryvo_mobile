import 'package:ryvo_admin/services/rbac_service.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

/// Merge roles/permissions from auth-hooks when the Supabase JWT omits app_metadata claims.
Future<SessionUser> enrichSessionUser(SessionUser user, String accessToken) async {
  try {
    final me = await RbacService().getMe(accessToken);
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
