import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/stores/auth_store.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child, required this.prefs});

  final Widget child;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: child,
    );
  }
}
