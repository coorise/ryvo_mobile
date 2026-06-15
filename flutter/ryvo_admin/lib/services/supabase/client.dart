import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ryvo_admin/configs/env.dart';

export 'package:ryvo_admin/core/common/session_user_mapper.dart';

SupabaseClient get supabase => Supabase.instance.client;

bool _supabaseReady = false;
bool get supabaseIsReady => _supabaseReady;

Future<void> initializeSupabase() async {
  if (Env.supabaseAnonKey.isEmpty) return;
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
  );
  _supabaseReady = true;
}
