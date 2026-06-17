import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:ryvo_admin/configs/const.dart';

/// Loads `lib/i18n/locales/*.json` — same keys as web i18next resources.
class AppI18n {
  AppI18n._();

  static final AppI18n instance = AppI18n._();

  Map<String, dynamic> _data = const {};
  String _languageCode = 'en';

  String get languageCode => _languageCode;
  Map<String, dynamic> get data => _data;

  Future<void> load(String languageCode) async {
    final code = AppConst.supportedLanguages.contains(languageCode)
        ? languageCode
        : 'en';
    final raw = await rootBundle.loadString('lib/i18n/locales/$code.json');
    _data = jsonDecode(raw) as Map<String, dynamic>;
    _languageCode = code;
  }

  /// Resolve dotted keys like `nav.profile` or `common.signOut`.
  String tr(String key) {
    final value = _resolve(_data, key.split('.'));
    if (value != null && value.isNotEmpty) return value;
    return key;
  }

  String? _resolve(dynamic node, List<String> parts) {
    if (parts.isEmpty) return node?.toString();
    if (node is! Map) return null;
    final next = node[parts.first];
    if (parts.length == 1) return next?.toString();
    return _resolve(next, parts.sublist(1));
  }
}
