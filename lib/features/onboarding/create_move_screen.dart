import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../moves/data/move_repository.dart';
import '../moves/domain/move_plan.dart';
import '../tasks/data/task_repository.dart';

class CreateMoveScreen extends ConsumerStatefulWidget {
  const CreateMoveScreen({super.key});

  @override
  ConsumerState<CreateMoveScreen> createState() => _CreateMoveScreenState();
}

class _CreateMoveScreenState extends ConsumerState<CreateMoveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  DateTime? _moveDate;
  double _rooms = 3;
  bool _hasStorage = false;
  bool _hasBalcony = false;
  bool _hasElevator = false;
  bool _saving = false;

  bool get _hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _fromController.text.trim().isNotEmpty ||
      _toController.text.trim().isNotEmpty ||
      _moveDate != null ||
      _rooms != 3 ||
      _hasStorage ||
      _hasBalcony ||
      _hasElevator;

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('לבטל את יצירת המעבר?'),
        content: const Text('השינויים שלא נשמרו יאבדו.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('המשך לעריכה'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('צא ללא שמירה'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _handleBack() async {
    if (_saving || !await _confirmExit() || !mounted) {
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );

    if (date != null && mounted) {
      setState(() => _moveDate = date);
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_moveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לבחור תאריך מעבר')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final session = await ref.read(authSessionProvider.future);
    final move = MovePlan(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty
          ? 'מעבר דירה'
          : _nameController.text.trim(),
      fromAddress: _fromController.text.trim(),
      toAddress: _toController.text.trim(),
      moveDate: _moveDate!,
      roomCount: _rooms.toInt(),
      hasStorage: _hasStorage,
      hasBalcony: _hasBalcony,
      hasElevator: _hasElevator,
      ownerUid: session.user?.uid,
      createdAt: now,
      updatedAt: now,
    );

    final moveRepository = await ref.read(moveRepositoryProvider.future);
    await moveRepository.saveMove(move);
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    await taskRepository.seedDefaults(
      moveId: move.id,
      moveDate: move.moveDate,
    );
    ref.invalidate(currentMoveProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(taskStatsProvider);

    if (!mounted) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 56),
            SizedBox(height: 16),
            Text(
              'המעבר נוצר בהצלחה!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'חזרה',
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            title: const Text('יצירת מעבר חדש'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'פרטי המעבר',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם המעבר (אופציונלי)',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'כתובת נוכחית',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'כתובת חדשה',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: Text(
                    _moveDate == null
                        ? 'בחירת תאריך מעבר'
                        : '${_moveDate!.day}/${_moveDate!.month}/${_moveDate!.year}',
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 22),
                Text(
                  'מספר חדרים: ${_rooms.toInt()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _rooms,
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: _rooms.toInt().toString(),
                  onChanged: (value) => setState(() => _rooms = value),
                ),
                SwitchListTile(
                  title: const Text('יש מחסן'),
                  value: _hasStorage,
                  onChanged: (value) => setState(() => _hasStorage = value),
                ),
                SwitchListTile(
                  title: const Text('יש מרפסת'),
                  value: _hasBalcony,
                  onChanged: (value) => setState(() => _hasBalcony = value),
                ),
                SwitchListTile(
                  title: const Text('יש מעלית'),
                  value: _hasElevator,
                  onChanged: (value) => setState(() => _hasElevator = value),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('יצירת המעבר'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
