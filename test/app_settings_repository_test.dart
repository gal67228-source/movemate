import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/settings/app_settings_repository.dart';
import 'package:movemate/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme mode is stored and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = AppSettingsRepository(LocalStorage(preferences));

    expect(repository.getThemeMode(), ThemeMode.system);

    await repository.saveThemeMode(ThemeMode.dark);
    expect(repository.getThemeMode(), ThemeMode.dark);

    await repository.saveThemeMode(ThemeMode.light);
    expect(repository.getThemeMode(), ThemeMode.light);
  });
}
