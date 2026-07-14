import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../moves/data/move_repository.dart';
import 'welcome_screen.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(currentMoveProvider).when(
          data: (move) => move == null ? const WelcomeScreen() : const DashboardScreen(),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('לא ניתן לטעון את נתוני המעבר.\n$error', textAlign: TextAlign.center),
              ),
            ),
          ),
        );
  }
}
