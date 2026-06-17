import 'package:ryvo/types/interfaces/schemas/session_user.dart';

const _internalRoles = [
  'super_admin',
  'admin',
  'staff',
  'moderator',
  'agent',
  'support',
];

bool isInternalPortalUser(SessionUser? user) {
  if (user == null) return false;
  return _internalRoles.any(user.roles.contains);
}
