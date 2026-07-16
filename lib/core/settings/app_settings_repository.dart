import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

const _themeModeKey = 'app_theme_mode';

class AppSettingsRepository {
  AppSettingsRepository(this._storage);

  final LocalStorage _storage;

  ThemeMode getThemeMode() {
    return switch (_storage.readString(_themeModeKey)) {
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
    return _storage.writeString(_themeModeKey, value);
  }
}

final appSettingsRepositoryProvider = FutureProvider<AppSettingsRepository>((ref) async {
  return AppSettingsRepository(await ref.watch(localStorageProvider.future));
});

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final repository = await ref.watch(appSettingsRepositoryProvider.future);
  return repository.getThemeMode();
});
