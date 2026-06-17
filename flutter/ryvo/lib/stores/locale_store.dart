import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo/configs/const.dart';
import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/stores/auth_store.dart';

const supportedAppLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('es'),
  Locale('zh'),
  Locale('de'),
];

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final code = prefs.getString(AppConst.storageLanguage) ?? 'en';
    if (AppConst.supportedLanguages.contains(code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> setLanguage(String languageCode) async {
    if (!AppConst.supportedLanguages.contains(languageCode)) return;
    await AppI18n.instance.load(languageCode);
    state = Locale(languageCode);
    await _prefs.setString(AppConst.storageLanguage, languageCode);
  }
}
