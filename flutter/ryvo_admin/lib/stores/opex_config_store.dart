import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ryvo_admin/lib/finance_speculative.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

const _storageKey = 'ryvo.finance.opex.v1';

class OpexConfigNotifier extends StateNotifier<List<OpexResource>> {
  OpexConfigNotifier(this._read, this._write) : super(defaultOpexResources) {
    _load();
  }

  final SharedPreferences Function() _read;
  final Future<bool> Function(String key, String value) _write;

  Future<void> _load() async {
    final raw = _read().getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map>()
          .map((e) => OpexResource.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (items.isNotEmpty) state = items;
    } catch (_) {}
  }

  Future<void> _persist() async {
    await _write(_storageKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> addResource(OpexResource resource) async {
    state = [...state, resource];
    await _persist();
  }

  Future<void> removeResource(String id) async {
    state = state.where((r) => r.id != id).toList(growable: false);
    await _persist();
  }
}

final opexConfigProvider =
    StateNotifierProvider<OpexConfigNotifier, List<OpexResource>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OpexConfigNotifier(
    () => prefs,
    (key, value) => prefs.setString(key, value),
  );
});
