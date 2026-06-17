import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/enrich_session_user.dart';
import 'package:ryvo_admin/services/index.dart';
import 'package:ryvo_admin/types/interfaces/schemas/session_user.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final authServiceProvider = Provider<AuthService?>((ref) {
  if (!supabaseIsReady) return null;
  return AuthService(supabase);
});

class AuthState {
  const AuthState({this.session, this.isReady = false});

  final AuthSession? session;
  final bool isReady;

  SessionUser? get user => session?.user;
  String? get accessToken => session?.accessToken;

  AuthState copyWith({AuthSession? session, bool? isReady}) {
    return AuthState(
      session: session ?? this.session,
      isReady: isReady ?? this.isReady,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthService? _auth;

  Future<void> _bootstrap() async {
    final auth = _auth;
    if (auth == null) {
      state = const AuthState(isReady: true);
      return;
    }
    final session = auth.currentSession();
    // Mark ready immediately so resume/cold-start does not hang on splash while
    // RBAC enrichment runs (network may be slow after backgrounding).
    state = AuthState(session: session, isReady: true);
    if (session != null) {
      unawaited(_applyEnrichedSession(session));
    }
    auth.authChanges().listen((eventSession) {
      state = AuthState(session: eventSession, isReady: true);
      if (eventSession != null) {
        unawaited(_applyEnrichedSession(eventSession));
      }
    });
  }

  Future<void> _applyEnrichedSession(AuthSession session) async {
    final token = session.accessToken;
    try {
      final enriched = await enrichAuthSession(session);
      if (state.accessToken != token) return;
      state = AuthState(session: enriched, isReady: true);
    } catch (_) {
      // Keep the Supabase session; RBAC claims may arrive on the next refresh.
    }
  }

  Future<void> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Supabase not configured — set SUPABASE_ANON_KEY via --dart-define');
    }
    var session = await auth.signIn(email: email, password: password);
    if (session == null) throw Exception('No session returned');
    session = await enrichAuthSession(session);
    state = AuthState(session: session, isReady: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConst.storageAuth, session.accessToken);
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConst.storageAuth);
    state = const AuthState(isReady: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
