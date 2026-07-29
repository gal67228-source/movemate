import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cloud/cloud_sync_provider.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_settings_repository.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MoveMateApp()));
}

class MoveMateApp extends ConsumerWidget {
  const MoveMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cloudSyncProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MoveMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
