import '../../packing/domain/packing_models.dart';
import '../../tasks/domain/move_task.dart';

class RoomRemainingItems {
  const RoomRemainingItems({required this.roomName, required this.items});

  final String roomName;
  final List<PackingItem> items;
}

class SmartMoveSummary {
  const SmartMoveSummary({
    required this.daysUntilMove,
    required this.readiness,
    required this.taskProgress,
    required this.packingProgress,
    required this.boxProgress,
    required this.shoppingProgress,
    required this.saleProgress,
    required this.upcomingTasks,
    required this.remainingByRoom,
    required this.insights,
  });

  final int daysUntilMove;
  final double readiness;
  final double taskProgress;
  final double packingProgress;
  final double boxProgress;
  final double shoppingProgress;
  final double saleProgress;
  final List<MoveTask> upcomingTasks;
  final List<RoomRemainingItems> remainingByRoom;
  final List<String> insights;

  int get readinessPercent => (readiness * 100).round();

  int get remainingItems => remainingByRoom.fold(
        0,
        (total, room) => total + room.items.fold(0, (sum, item) => sum + item.quantity),
      );
}

double calculateReadiness(Iterable<double> values) {
  final active = values.where((value) => value.isFinite).toList();
  if (active.isEmpty) {
    return 0;
  }
  final result = active.fold<double>(0, (sum, value) => sum + value) / active.length;
  return result.clamp(0, 1).toDouble();
}
