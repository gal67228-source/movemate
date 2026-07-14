import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

class LocalStorage {
  LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  Map<String, Object?>? readObject(String key) {
    final value = _preferences.getString(key);
    if (value == null) return null;
    return Map<String, Object?>.from(jsonDecode(value) as Map);
  }

  List<Map<String, Object?>> readObjectList(String key) {
    final value = _preferences.getString(key);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<void> writeObject(String key, Map<String, Object?> value) => _preferences.setString(key, jsonEncode(value));

  Future<void> writeObjectList(String key, List<Map<String, Object?>> value) => _preferences.setString(key, jsonEncode(value));
}

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  return LocalStorage(await ref.watch(sharedPreferencesProvider.future));
});
