import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/auth/app_user.dart';
import 'package:movemate/core/auth/auth_providers.dart';
import 'package:movemate/core/auth/auth_service.dart';
import 'package:movemate/core/database/app_database.dart';
import 'package:movemate/core/database/database_provider.dart';
import 'package:movemate/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LocalTestAuthService implements AuthService {
  @override
  bool get isFirebaseConfigured => false;

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  Future<void> continueLocally() async {}

  @override
  Future<void> disableLocalMode() async {}

  @override
  Future<bool> isLocalModeEnabled() async => true;

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('welcome screen opens in Hebrew', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          authServiceProvider.overrideWith(
            (ref) async => _LocalTestAuthService(),
          ),
        ],
        child: const MoveMateApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MoveMate'), findsOneWidget);
    expect(find.text('יצירת מעבר חדש'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
  });
}
