import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../moves/data/move_repository.dart';
import '../data/task_repository.dart';
import '../domain/move_task.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId});

  final String? taskId;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.general;
  MoveTask? _existingTask;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadTask(List<MoveTask> tasks) {
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (widget.taskId == null) {
      return;
    }
    final matches = tasks.where((task) => task.id == widget.taskId);
    if (matches.isEmpty) {
      return;
    }
    final task = matches.first;
    _existingTask = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _dueDate = task.dueDate;
    _priority = task.priority;
    _category = task.category;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    if (move == null) {
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final task = MoveTask(
      id: _existingTask?.id ?? now.microsecondsSinceEpoch.toString(),
      moveId: move.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      category: _category,
      isCompleted: _existingTask?.isCompleted ?? false,
      createdAt: _existingTask?.createdAt ?? now,
    );
    final repository = await ref.read(taskRepositoryProvider.future);
    await repository.upsert(task);
    ref.invalidate(tasksProvider);
    ref.invalidate(taskStatsProvider);
    if (!mounted) {
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.taskId == null ? 'משימה חדשה' : 'עריכת משימה')),
      body: tasksAsync.when(
        data: (tasks) {
          _loadTask(tasks);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: widget.taskId == null,
                  decoration: const InputDecoration(labelText: 'כותרת', prefixIcon: Icon(Icons.title)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'יש להזין כותרת' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'תיאור', prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TaskCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'קטגוריה', prefixIcon: Icon(Icons.category_outlined)),
                  items: TaskCategory.values
                      .map((category) => DropdownMenuItem(value: category, child: Text(categoryLabel(category))))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? TaskCategory.general),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'עדיפות', prefixIcon: Icon(Icons.flag_outlined)),
                  items: TaskPriority.values
                      .map((priority) => DropdownMenuItem(value: priority, child: Text(priorityLabel(priority))))
                      .toList(),
                  onChanged: (value) => setState(() => _priority = value ?? TaskPriority.medium),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(_dueDate == null ? 'ללא תאריך יעד' : DateFormat('dd/MM/yyyy').format(_dueDate!)),
                  trailing: _dueDate == null
                      ? const Icon(Icons.chevron_left)
                      : IconButton(onPressed: () => setState(() => _dueDate = null), icon: const Icon(Icons.clear)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('שמירה'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('לא ניתן לטעון את המשימה: $error')),
      ),
    );
  }
}
