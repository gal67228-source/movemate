import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/main.dart';

void main() {
  testWidgets('welcome screen opens in Hebrew', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MoveMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MoveMate'), findsOneWidget);
    expect(find.text('יצירת מעבר חדש'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
  });
}
