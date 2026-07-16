import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/theme/app_theme.dart';

void main() {
  test('light and dark themes use Material 3 and the expected brightness', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('interactive controls keep accessible minimum sizes', () {
    final minimumSize = AppTheme.light.filledButtonTheme.style?.minimumSize
        ?.resolve(<WidgetState>{});

    expect(minimumSize, isNotNull);
    expect(minimumSize!.height, greaterThanOrEqualTo(48));
  });
}
