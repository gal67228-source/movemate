import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/backup/backup_providers.dart';
import '../../../core/storage/local_storage.dart';
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
  bool _authWorking = false;

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
    final updated = move.copyWith(
      name: _nameController.text.trim(),
      fromAddress: _fromController.text.trim(),
      toAddress: _toController.text.trim(),
      moveDate: _moveDate!,
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

  Future<void> _signIn() async {
    setState(() => _authWorking = true);
    try {
      final service = await ref.read(authServiceProvider.future);
      final user = await service.signInWithGoogle();
      final repository = await ref.read(moveRepositoryProvider.future);
      await repository.assignOwnerToCurrentMove(user.uid);
      ref.invalidate(authSessionProvider);
      ref.invalidate(currentMoveProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא ניתן להתחבר: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _authWorking = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _authWorking = true);
    final service = await ref.read(authServiceProvider.future);
    await service.signOut();
    ref.invalidate(authSessionProvider);
    if (!mounted) {
      return;
    }
    setState(() => _authWorking = false);
    context.go('/');
  }

  Future<void> _exportBackup() async {
    try {
      final result = await ref.read(backupServiceProvider).exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('יוצא גיבוי של ${result.recordCount} רשומות')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ייצוא הגיבוי נכשל: $error')),
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזור גיבוי'),
        content: const Text('השחזור יחליף את הנתונים המקומיים הנוכחיים.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('בחירת קובץ')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await ref.read(backupServiceProvider).importBackup();
      if (result == null) return;
      ref.read(storageRevisionProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שוחזרו ${result.recordCount} רשומות')),
      );
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שחזור הגיבוי נכשל: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final moveAsync = ref.watch(currentMoveProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final sessionAsync = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: moveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('לא ניתן לטעון הגדרות: $error'),
        ),
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
                Text('חשבון', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                sessionAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline_rounded),
                      title: const Text('לא ניתן לטעון את החשבון'),
                      subtitle: Text('$error'),
                    ),
                  ),
                  data: (session) {
                    final user = session.user;
                    return Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              foregroundImage: user?.photoUrl == null
                                  ? null
                                  : NetworkImage(user!.photoUrl!),
                              child: user == null
                                  ? const Icon(Icons.person_outline_rounded)
                                  : Text(
                                      user.displayName.isEmpty
                                          ? '?'
                                          : user.displayName.substring(0, 1),
                                    ),
                            ),
                            title: Text(
                              user?.displayName ?? 'מצב מקומי',
                            ),
                            subtitle: Text(
                              user?.email.isNotEmpty == true
                                  ? user!.email
                                  : session.firebaseConfigured
                                      ? 'הנתונים נשמרים במכשיר בלבד'
                                      : 'Firebase עדיין לא הוגדר',
                            ),
                            trailing: Chip(label: Text(move.plan)),
                          ),
                          const Divider(height: 1),
                          if (user == null)
                            ListTile(
                              leading: const Icon(Icons.login_rounded),
                              title: const Text('התחברות עם Google'),
                              subtitle: const Text(
                                'שייך את המעבר לחשבון שלך לקראת סנכרון הענן',
                              ),
                              enabled: !_authWorking,
                              onTap: _signIn,
                            )
                          else
                            ListTile(
                              leading: const Icon(Icons.logout_rounded),
                              title: const Text('התנתקות'),
                              enabled: !_authWorking,
                              onTap: _signOut,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded),
                    title: const Text('שיתוף וסנכרון'),
                    subtitle: const Text('סנכרון בענן והזמנת משתמשים'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => context.push('/sharing'),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'פרטי המעבר',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                Text('גיבוי ושחזור', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.upload_file_rounded),
                        title: const Text('ייצוא גיבוי JSON'),
                        subtitle: const Text('שמירת כל נתוני המעבר בקובץ'),
                        onTap: _exportBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings_backup_restore_rounded),
                        title: const Text('ייבוא ושחזור'),
                        subtitle: const Text('שחזור נתונים מקובץ MoveMate'),
                        onTap: _importBackup,
                      ),
                    ],
                  ),
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

  Future<void> _exportBackup() async {
    try {
      final result = await ref.read(backupServiceProvider).exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('יוצא גיבוי של ${result.recordCount} רשומות')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ייצוא הגיבוי נכשל: $error')),
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזור גיבוי'),
        content: const Text('השחזור יחליף את הנתונים המקומיים הנוכחיים.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('בחירת קובץ')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await ref.read(backupServiceProvider).importBackup();
      if (result == null) return;
      ref.read(storageRevisionProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שוחזרו ${result.recordCount} רשומות')),
      );
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שחזור הגיבוי נכשל: $error')),
      );
    }
  }

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
