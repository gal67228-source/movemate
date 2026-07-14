import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateMoveScreen extends StatefulWidget {
  const CreateMoveScreen({super.key});

  @override
  State<CreateMoveScreen> createState() => _CreateMoveScreenState();
}

class _CreateMoveScreenState extends State<CreateMoveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'המעבר שלנו');
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _moveDate;
  double _rooms = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (date != null) setState(() => _moveDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_moveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('יש לבחור תאריך מעבר')));
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('יצירת מעבר חדש')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('פרטי המעבר', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'שם המעבר', prefixIcon: Icon(Icons.edit_rounded)),
              validator: (value) => value == null || value.trim().isEmpty ? 'יש להזין שם' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _fromController, decoration: const InputDecoration(labelText: 'כתובת נוכחית', prefixIcon: Icon(Icons.home_outlined))),
            const SizedBox(height: 14),
            TextFormField(controller: _toController, decoration: const InputDecoration(labelText: 'כתובת חדשה', prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(_moveDate == null ? 'בחירת תאריך מעבר' : '${_moveDate!.day}/${_moveDate!.month}/${_moveDate!.year}'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 22),
            Text('מספר חדרים: ${_rooms.toInt()}', style: Theme.of(context).textTheme.titleMedium),
            Slider(value: _rooms, min: 1, max: 8, divisions: 7, label: _rooms.toInt().toString(), onChanged: (value) => setState(() => _rooms = value)),
            const SizedBox(height: 28),
            FilledButton(onPressed: _submit, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('יצירת המעבר'))),
          ],
        ),
      ),
    );
  }
}
