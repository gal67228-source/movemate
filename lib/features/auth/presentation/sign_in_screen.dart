import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_service.dart';
import '../../moves/data/move_repository.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _working = false;

  Future<void> _signIn() async {
    setState(() => _working = true);
    try {
      final service = await ref.read(authServiceProvider.future);
      final user = await service.signInWithGoogle();
      final moveRepository = await ref.read(moveRepositoryProvider.future);
      await moveRepository.assignOwnerToCurrentMove(user.uid);
      ref.invalidate(authSessionProvider);
      ref.invalidate(currentMoveProvider);
    } on AuthCancelledException {
      // The user closed the Google account chooser.
    } on AuthConfigurationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ההתחברות נכשלה: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _continueLocally() async {
    setState(() => _working = true);
    final service = await ref.read(authServiceProvider.future);
    await service.continueLocally();
    ref.invalidate(authSessionProvider);
    if (mounted) {
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 62),
              ),
              const SizedBox(height: 28),
              Text(
                'MoveMate',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'התחבר עם Google כדי לשייך את המעבר לחשבון שלך ולהכין אותו לסנכרון עתידי.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (session?.firebaseConfigured == false) ...[
                const SizedBox(height: 18),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Google עדיין לא הוגדר בפרויקט Firebase. האפליקציה תמשיך לעבוד במצב מקומי.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _signIn,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('התחברות עם Google'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _continueLocally,
                  icon: const Icon(Icons.phone_android_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('המשך במצב מקומי'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
