import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sign-in screen keeps onboarding copy minimal', () {
    final source = File(
      'lib/features/auth/presentation/sign_in_screen.dart',
    ).readAsStringSync();

    expect(source, contains('התחבר עם Google'));
    expect(source, contains('המשך במצב מקומי'));
    expect(source, isNot(contains('כדי לשייך את המעבר')));
    expect(source, isNot(contains('Google עדיין לא הוגדר')));
  });

  test('welcome screen has no demo preview action', () {
    final source = File(
      'lib/features/onboarding/welcome_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('הצגת מסך לדוגמה')));
    expect(source, contains("context.push('/create-move')"));
  });

  test('new move supports safe back navigation', () {
    final source = File(
      'lib/features/onboarding/create_move_screen.dart',
    ).readAsStringSync();

    expect(source, contains('PopScope'));
    expect(source, contains('לבטל את יצירת המעבר?'));
    expect(source, contains('צא ללא שמירה'));
  });

  test('new move falls back to a useful default name', () {
    final source = File(
      'lib/features/onboarding/create_move_screen.dart',
    ).readAsStringSync();

    expect(source, contains("? 'מעבר דירה'"));
    expect(source, contains('המעבר נוצר בהצלחה!'));
  });
}
