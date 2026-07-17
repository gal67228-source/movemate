import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/sync/sync_providers.dart';
import '../../moves/data/move_repository.dart';

class SharingScreen extends ConsumerStatefulWidget {
  const SharingScreen({super.key});

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends ConsumerState<SharingScreen> {
  final _codeController = TextEditingController();
  ShareInvite? _invite;
  bool _working = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createInvite(CloudSyncService service) async {
    setState(() => _working = true);
    try {
      final invite = await service.createInvite();
      if (mounted) {
        setState(() => _invite = invite);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _acceptInvite(CloudSyncService service) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      return;
    }
    setState(() => _working = true);
    try {
      await service.acceptInvite(code);
      ref.invalidate(localStorageProvider);
      ref.invalidate(moveRepositoryProvider);
      ref.invalidate(currentMoveProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הצטרפת למעבר המשותף')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('לא ניתן להשלים את הפעולה: $error')),
    );
  }

  Future<void> _removeMember(
    CloudSyncService service,
    SharedMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסרת משתמש'),
        content: Text('להסיר את ${member.displayName} מהמעבר?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('הסר'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.removeMember(member.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authSessionProvider);
    final moveAsync = ref.watch(currentMoveProvider);
    final syncAsync = ref.watch(cloudSyncServiceProvider);
    final statusAsync = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('שיתוף וסנכרון')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (session) {
          if (session.user == null) {
            return const _SignInRequired();
          }
          return syncAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
            data: (service) {
              if (service == null) {
                return const _SignInRequired();
              }
              return moveAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('$error')),
                data: (move) {
                  final isOwner = move?.ownerUid == session.user!.uid;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      statusAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => _SyncCard(
                          title: 'שגיאת סנכרון',
                          subtitle: '$error',
                          icon: Icons.cloud_off_rounded,
                        ),
                        data: (status) => _SyncCard(
                          title: status.syncing
                              ? 'מסנכרן עכשיו'
                              : status.available
                                  ? 'הסנכרון פעיל'
                                  : 'סנכרון לא פעיל',
                          subtitle: status.error ??
                              (status.lastSyncedAt == null
                                  ? 'עדיין לא בוצע סנכרון'
                                  : 'עודכן לאחרונה ${_formatTime(status.lastSyncedAt!)}'),
                          icon: status.error == null
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isOwner ? 'הזמנת משתמשים' : 'הצטרפות למעבר',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (isOwner) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'צור קוד הזמנה ושלח אותו לאדם שברצונך לצרף.',
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: _working
                                      ? null
                                      : () => _createInvite(service),
                                  icon: const Icon(Icons.person_add_alt_1_rounded),
                                  label: const Text('יצירת קוד הזמנה'),
                                ),
                                if (_invite != null) ...[
                                  const SizedBox(height: 16),
                                  SelectableText(
                                    _invite!.code,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(letterSpacing: 3),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: _invite!.code),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('הקוד הועתק'),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.copy_rounded),
                                    label: const Text('העתקת הקוד'),
                                  ),
                                  Text(
                                    'הקוד תקף עד ${_formatDate(_invite!.expiresAt)}',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'משתמשים משותפים',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<SharedMember>>(
                          stream: service.watchMembers(),
                          builder: (context, snapshot) {
                            final members = snapshot.data ?? const [];
                            if (members.isEmpty) {
                              return const Card(
                                child: ListTile(
                                  leading: Icon(Icons.group_outlined),
                                  title: Text('עדיין לא צורפו משתמשים'),
                                ),
                              );
                            }
                            return Column(
                              children: members
                                  .map(
                                    (member) => Card(
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          child: Icon(Icons.person_rounded),
                                        ),
                                        title: Text(member.displayName),
                                        subtitle: Text(member.email),
                                        trailing: IconButton(
                                          tooltip: 'הסרה',
                                          onPressed: () =>
                                              _removeMember(service, member),
                                          icon: const Icon(
                                            Icons.person_remove_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ] else ...[
                        _JoinCard(
                          controller: _codeController,
                          working: _working,
                          onJoin: () => _acceptInvite(service),
                        ),
                      ],
                      if (isOwner) ...[
                        const SizedBox(height: 24),
                        Text(
                          'יש לך קוד הזמנה למעבר אחר?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _JoinCard(
                          controller: _codeController,
                          working: _working,
                          onJoin: () => _acceptInvite(service),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.controller,
    required this.working,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool working;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'קוד הזמנה',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: working ? null : onJoin,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('הצטרפות למעבר'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'יש להתחבר עם Google כדי לסנכרן ולשתף מעבר.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
