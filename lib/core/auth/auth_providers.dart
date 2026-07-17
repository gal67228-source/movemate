import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';
import 'app_user.dart';
import 'auth_service.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.localMode,
    required this.firebaseConfigured,
  });

  final AppUser? user;
  final bool localMode;
  final bool firebaseConfigured;

  bool get canEnterApp => user != null || localMode;
}

final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final preferences = await ref.watch(appSettingsPreferencesProvider.future);
  return FirebaseGoogleAuthService.create(preferences);
});

final authSessionProvider = FutureProvider<AuthSession>((ref) async {
  final service = await ref.watch(authServiceProvider.future);
  final localMode = await service.isLocalModeEnabled();
  final user = service.currentUser;
  return AuthSession(
    user: user,
    localMode: localMode,
    firebaseConfigured: service.isFirebaseConfigured,
  );
});
