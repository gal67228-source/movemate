import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../auth/presentation/sign_in_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../moves/data/move_repository.dart';
import 'welcome_screen.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authSessionProvider).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'לא ניתן לאתחל את החשבון.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          data: (session) {
            if (!session.canEnterApp) {
              return const SignInScreen();
            }
            return ref.watch(currentMoveProvider).when(
                  data: (move) => move == null
                      ? const WelcomeScreen()
                      : const DashboardScreen(),
                  loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'לא ניתן לטעון את נתוני המעבר.\n$error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
          },
        );
  }
}
