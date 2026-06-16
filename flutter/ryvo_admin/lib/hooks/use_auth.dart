import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

/// Mirrors web `useAuth()` hook — Riverpod wrapper for Flutter widgets.
AuthViewModel useAuth(WidgetRef ref) {
  final state = ref.watch(authProvider);
  final notifier = ref.read(authProvider.notifier);
  return AuthViewModel(
    user: state.user,
    accessToken: state.accessToken,
    isReady: state.isReady,
    signOut: notifier.signOut,
    signIn: notifier.signIn,
  );
}

class AuthViewModel {
  const AuthViewModel({
    required this.user,
    required this.accessToken,
    required this.isReady,
    required this.signOut,
    required this.signIn,
  });

  final SessionUser? user;
  final String? accessToken;
  final bool isReady;
  final Future<void> Function() signOut;
  final Future<void> Function(String email, String password) signIn;
}
