import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/onboarding/create_move_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/tasks/tasks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/create-move', builder: (context, state) => const CreateMoveScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),
    ],
  );
});
