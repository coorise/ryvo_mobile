import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo_admin/services/supabase/client.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Future<AuthSession?> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    final session = res.session;
    if (session == null) return null;
    return AuthSession(
      accessToken: session.accessToken,
      user: mapSupabaseUserToSession(session.user, accessToken: session.accessToken),
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  AuthSession? currentSession() {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return AuthSession(
      accessToken: session.accessToken,
      user: mapSupabaseUserToSession(session.user, accessToken: session.accessToken),
    );
  }

  Stream<AuthSession?> authChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session == null) return null;
      return AuthSession(
        accessToken: session.accessToken,
        user: mapSupabaseUserToSession(session.user, accessToken: session.accessToken),
      );
    });
  }
}
