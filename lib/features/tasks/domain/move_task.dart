enum TaskPriority { low, medium, high }

enum TaskCategory { moving, packing, bureaucracy, newHome, shopping, repairs, general }

class MoveTask {
  const MoveTask({
    required this.id,
    required this.moveId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String moveId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;

  MoveTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
  }) {
    return MoveTask(
      id: id,
      moveId: moveId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.name,
        'category': category.name,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoveTask.fromJson(Map<String, Object?> json) => MoveTask(
        id: json['id']! as String,
        moveId: json['moveId']! as String,
        title: json['title']! as String,
        description: (json['description'] as String?) ?? '',
        dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate']! as String),
        priority: TaskPriority.values.byName((json['priority'] as String?) ?? TaskPriority.medium.name),
        category: TaskCategory.values.byName((json['category'] as String?) ?? TaskCategory.general.name),
        isCompleted: (json['isCompleted'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class TaskStats {
  const TaskStats({required this.total, required this.completed});

  final int total;
  final int completed;
  int get open => total - completed;
  double get progress => total == 0 ? 0 : completed / total;
}

TaskStats calculateTaskStats(Iterable<MoveTask> tasks) {
  final list = tasks.toList();
  return TaskStats(total: list.length, completed: list.where((task) => task.isCompleted).length);
}

String priorityLabel(TaskPriority priority) => switch (priority) {
      TaskPriority.low => 'נמוכה',
      TaskPriority.medium => 'בינונית',
      TaskPriority.high => 'גבוהה',
    };

String categoryLabel(TaskCategory category) => switch (category) {
      TaskCategory.moving => 'הובלה',
      TaskCategory.packing => 'אריזה',
      TaskCategory.bureaucracy => 'בירוקרטיה',
      TaskCategory.newHome => 'בית חדש',
      TaskCategory.shopping => 'קניות',
      TaskCategory.repairs => 'תיקונים',
      TaskCategory.general => 'כללי',
    };
