import 'package:equatable/equatable.dart';

/// Mirrors web `SessionUser` — extend as schemas port from TypeScript.
class SessionUser extends Equatable {
  const SessionUser({
    required this.id,
    required this.email,
    required this.roles,
    this.permissions = const [],
    this.emailVerified = false,
    this.fullName,
  });

  final String id;
  final String? email;
  final List<String> roles;
  final List<String> permissions;
  final bool emailVerified;
  final String? fullName;

  @override
  List<Object?> get props => [id, email, roles, permissions, emailVerified, fullName];
}

class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.accessToken});

  final SessionUser user;
  final String accessToken;

  @override
  List<Object?> get props => [user, accessToken];
}
