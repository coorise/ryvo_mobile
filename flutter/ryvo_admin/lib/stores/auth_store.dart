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
    var session = auth.currentSession();
    if (session != null) {
      session = await enrichAuthSession(session);
    }
    state = AuthState(session: session, isReady: true);
    auth.authChanges().listen((eventSession) async {
      var session = eventSession;
      if (session != null) {
        session = await enrichAuthSession(session);
      }
      state = AuthState(session: session, isReady: true);
    });
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
