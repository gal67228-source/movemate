import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/budget/presentation/budget_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/onboarding/create_move_screen.dart';
import '../../features/onboarding/startup_screen.dart';
import '../../features/moving_day/presentation/moving_day_screen.dart';
import '../../features/packing/presentation/box_editor_screen.dart';
import '../../features/packing/presentation/boxes_screen.dart';
import '../../features/packing/presentation/room_inventory_screen.dart';
import '../../features/packing/presentation/rooms_screen.dart';
import '../../features/sales/presentation/sale_editor_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/tasks/presentation/task_editor_screen.dart';
import '../../features/tasks/tasks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
      GoRoute(
        path: '/create-move',
        builder: (context, state) => const CreateMoveScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),
      GoRoute(
        path: '/moving-day',
        builder: (context, state) => const MovingDayScreen(),
      ),
      GoRoute(
        path: '/tasks/edit',
        builder: (context, state) => TaskEditorScreen(
          taskId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(path: '/rooms', builder: (context, state) => const RoomsScreen()),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) => RoomInventoryScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(path: '/boxes', builder: (context, state) => const BoxesScreen()),
      GoRoute(path: '/sales', builder: (context, state) => const SalesScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(path: '/shopping', builder: (context, state) => const ShoppingScreen()),
      GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
      GoRoute(
        path: '/sales/edit',
        builder: (context, state) => SaleEditorScreen(
          itemId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/boxes/edit',
        builder: (context, state) => BoxEditorScreen(
          boxId: state.uri.queryParameters['id'],
        ),
      ),
    ],
  );
});
