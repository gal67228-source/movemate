enum MovingDayItemStatus { waiting, loaded, arrived, checked }

extension MovingDayItemStatusLabel on MovingDayItemStatus {
  String get label => switch (this) {
        MovingDayItemStatus.waiting => 'ממתין',
        MovingDayItemStatus.loaded => 'הועמס',
        MovingDayItemStatus.arrived => 'הגיע',
        MovingDayItemStatus.checked => 'נבדק',
      };
}

class MovingDayItem {
  const MovingDayItem({
    required this.id,
    required this.moveId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.notes = '',
    this.isCustom = false,
  });

  final String id;
  final String moveId;
  final String title;
  final MovingDayItemStatus status;
  final DateTime createdAt;
  final String notes;
  final bool isCustom;

  MovingDayItem copyWith({
    String? title,
    MovingDayItemStatus? status,
    String? notes,
  }) {
    return MovingDayItem(
      id: id,
      moveId: moveId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      isCustom: isCustom,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'title': title,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'isCustom': isCustom,
      };

  factory MovingDayItem.fromJson(Map<String, Object?> json) {
    return MovingDayItem(
      id: json['id']! as String,
      moveId: json['moveId']! as String,
      title: json['title']! as String,
      status: MovingDayItemStatus.values.byName(
        json['status'] as String? ?? MovingDayItemStatus.waiting.name,
      ),
      createdAt: DateTime.parse(json['createdAt']! as String),
      notes: json['notes'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class MovingDayStats {
  const MovingDayStats({
    required this.totalBoxes,
    required this.loadedBoxes,
    required this.arrivedBoxes,
    required this.unpackedBoxes,
    required this.totalChecklistItems,
    required this.checkedChecklistItems,
    required this.openTodayTasks,
    required this.unpackedInventoryItems,
  });

  final int totalBoxes;
  final int loadedBoxes;
  final int arrivedBoxes;
  final int unpackedBoxes;
  final int totalChecklistItems;
  final int checkedChecklistItems;
  final int openTodayTasks;
  final int unpackedInventoryItems;

  int get boxesStillAtHome => totalBoxes - loadedBoxes;

  double get checklistProgress => totalChecklistItems == 0
      ? 0
      : checkedChecklistItems / totalChecklistItems;
}
