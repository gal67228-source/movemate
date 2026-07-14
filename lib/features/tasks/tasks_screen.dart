import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _tasks = <({String title, bool done})>[
    (title: 'להזמין חברת הובלה', done: true),
    (title: 'לקנות קרטונים וסרט הדבקה', done: false),
    (title: 'לעדכן כתובת בחשבונות', done: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('משימות')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            child: CheckboxListTile(
              value: task.done,
              title: Text(task.title, style: TextStyle(decoration: task.done ? TextDecoration.lineThrough : null)),
              subtitle: const Text('עדיפות בינונית'),
              onChanged: (value) => setState(() => _tasks[index] = (title: task.title, done: value ?? false)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}
