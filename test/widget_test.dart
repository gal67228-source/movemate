import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/storage/local_storage.dart';
import 'package:movemate/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('welcome screen opens in Hebrew', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith(
            (ref) async => LocalStorage(preferences),
          ),
        ],
        child: const MoveMateApp(),
      ),
    );

    // Pump a bounded number of frames instead of pumpAndSettle. The app has
    // asynchronous providers and router transitions that may keep scheduling
    // frames even though the welcome screen is already ready for assertions.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MoveMate'), findsOneWidget);
    expect(find.text('יצירת מעבר חדש'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
  });
}
