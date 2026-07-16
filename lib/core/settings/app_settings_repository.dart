import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';

class AppSettingsRepository {
  AppSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  ThemeMode getThemeMode() {
    return switch (_preferences.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _preferences.setString(_themeModeKey, value);
  }
}

final appSettingsPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final appSettingsRepositoryProvider = FutureProvider<AppSettingsRepository>((ref) async {
  final preferences = await ref.watch(appSettingsPreferencesProvider.future);
  return AppSettingsRepository(preferences);
});

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final repository = await ref.watch(appSettingsRepositoryProvider.future);
  return repository.getThemeMode();
});
