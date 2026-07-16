import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings_repository.dart';
import '../../moves/data/move_repository.dart';
import '../../moves/domain/move_plan.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _moveDate;
  MovePlan? _loadedMove;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _loadMove(MovePlan move) {
    if (_loadedMove?.id == move.id) {
      return;
    }
    _loadedMove = move;
    _nameController.text = move.name;
    _fromController.text = move.fromAddress;
    _toController.text = move.toAddress;
    _moveDate = move.moveDate;
  }

  Future<void> _pickDate() async {
    final current = _moveDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (selected != null && mounted) {
      setState(() => _moveDate = selected);
    }
  }

  Future<void> _saveMove(MovePlan move) async {
    if (!_formKey.currentState!.validate() || _moveDate == null) {
      return;
    }
    setState(() => _saving = true);
    final updated = MovePlan(
      id: move.id,
      name: _nameController.text.trim(),
      fromAddress: _fromController.text.trim(),
      toAddress: _toController.text.trim(),
      moveDate: _moveDate!,
      roomCount: move.roomCount,
      hasStorage: move.hasStorage,
      hasBalcony: move.hasBalcony,
      hasElevator: move.hasElevator,
    );
    final repository = await ref.read(moveRepositoryProvider.future);
    await repository.saveMove(updated);
    ref.invalidate(currentMoveProvider);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('פרטי המעבר נשמרו')),
    );
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    final repository = await ref.read(appSettingsRepositoryProvider.future);
    await repository.saveThemeMode(mode);
    ref.invalidate(themeModeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final moveAsync = ref.watch(currentMoveProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: moveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('לא ניתן לטעון הגדרות: $error')),
        data: (move) {
          if (move == null) {
            return const Center(child: Text('לא נמצא מעבר פעיל'));
          }
          _loadMove(move);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('פרטי המעבר', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם המעבר',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'יש להזין שם מעבר'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'כתובת נוכחית',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'כתובת חדשה',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('תאריך מעבר'),
                  subtitle: Text(
                    '${_moveDate!.day}/${_moveDate!.month}/${_moveDate!.year}',
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _saveMove(move),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('שמירת פרטי המעבר'),
                ),
                const SizedBox(height: 28),
                Text('מראה', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _ThemeOptionTile(
                        title: 'לפי הגדרות המכשיר',
                        icon: Icons.phone_android_rounded,
                        value: ThemeMode.system,
                        selected: themeMode == ThemeMode.system,
                        onTap: _changeTheme,
                      ),
                      _ThemeOptionTile(
                        title: 'מצב בהיר',
                        icon: Icons.light_mode_outlined,
                        value: ThemeMode.light,
                        selected: themeMode == ThemeMode.light,
                        onTap: _changeTheme,
                      ),
                      _ThemeOptionTile(
                        title: 'מצב כהה',
                        icon: Icons.dark_mode_outlined,
                        value: ThemeMode.dark,
                        selected: themeMode == ThemeMode.dark,
                        onTap: _changeTheme,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final ThemeMode value;
  final bool selected;
  final ValueChanged<ThemeMode> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      selected: selected,
      onTap: () => onTap(value),
    );
  }
}
