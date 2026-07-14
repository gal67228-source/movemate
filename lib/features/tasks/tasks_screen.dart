import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'data/task_repository.dart';
import 'domain/move_task.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _query = '';
  bool _showCompleted = true;

  Future<void> _toggleTask(MoveTask task) async {
    final repository = await ref.read(taskRepositoryProvider.future);
    await repository.upsert(task.copyWith(isCompleted: !task.isCompleted));
    ref.invalidate(tasksProvider);
    ref.invalidate(taskStatsProvider);
  }

  Future<void> _deleteTask(MoveTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת משימה'),
        content: Text('למחוק את "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('מחיקה')),
        ],
      ),
    );
    if (confirmed != true) return;
    final repository = await ref.read(taskRepositoryProvider.future);
    await repository.delete(task.id);
    ref.invalidate(tasksProvider);
    ref.invalidate(taskStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('משימות'),
        actions: [
          IconButton(
            tooltip: _showCompleted ? 'הסתר משימות שהושלמו' : 'הצג משימות שהושלמו',
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            icon: Icon(_showCompleted ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'חיפוש משימה',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((task) {
                  final matchesStatus = _showCompleted || !task.isCompleted;
                  final matchesQuery = _query.isEmpty ||
                      task.title.toLowerCase().contains(_query) ||
                      task.description.toLowerCase().contains(_query);
                  return matchesStatus && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_alt_rounded, size: 64),
                          SizedBox(height: 12),
                          Text('אין משימות להצגה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('לחץ על כפתור הפלוס כדי להוסיף משימה חדשה.', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tasksProvider);
                    await ref.read(tasksProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return _TaskCard(
                        task: task,
                        onToggle: () => _toggleTask(task),
                        onEdit: () => context.push('/tasks/edit?id=${task.id}'),
                        onDelete: () => _deleteTask(task),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('לא ניתן לטעון משימות: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final MoveTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate == null ? 'ללא תאריך' : DateFormat('dd/MM/yyyy').format(task.dueDate!);
    final priorityColor = switch (task.priority) {
      TaskPriority.low => Theme.of(context).colorScheme.secondary,
      TaskPriority.medium => Theme.of(context).colorScheme.tertiary,
      TaskPriority.high => Theme.of(context).colorScheme.error,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(value: task.isCompleted, onChanged: (value) => onToggle()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _TaskTag(icon: Icons.category_outlined, text: categoryLabel(task.category)),
                          _TaskTag(icon: Icons.calendar_today_outlined, text: dueDate),
                          _TaskTag(icon: Icons.flag_outlined, text: priorityLabel(task.priority), color: priorityColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('עריכה')),
                  PopupMenuItem(value: 'delete', child: Text('מחיקה')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTag extends StatelessWidget {
  const _TaskTag({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
