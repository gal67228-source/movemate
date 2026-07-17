import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_user.dart';

const _localModeKey = 'auth_local_mode';

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

abstract class AuthService {
  bool get isFirebaseConfigured;

  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

  Future<bool> isLocalModeEnabled();

  Future<void> continueLocally();

  Future<void> disableLocalMode();
}

class FirebaseGoogleAuthService implements AuthService {
  FirebaseGoogleAuthService._({
    required SharedPreferences preferences,
    required bool firebaseConfigured,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _preferences = preferences,
        _firebaseConfigured = firebaseConfigured,
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final SharedPreferences _preferences;
  final bool _firebaseConfigured;
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static Future<FirebaseGoogleAuthService> create(
    SharedPreferences preferences,
  ) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return FirebaseGoogleAuthService._(
        preferences: preferences,
        firebaseConfigured: true,
        firebaseAuth: FirebaseAuth.instance,
      );
    } catch (_) {
      return FirebaseGoogleAuthService._(
        preferences: preferences,
        firebaseConfigured: false,
      );
    }
  }

  @override
  bool get isFirebaseConfigured => _firebaseConfigured;

  @override
  AppUser? get currentUser => _toAppUser(_firebaseAuth?.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    final auth = _firebaseAuth;
    if (auth == null) {
      return Stream<AppUser?>.value(null);
    }
    return auth.authStateChanges().map(_toAppUser);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final auth = _firebaseAuth;
    if (!_firebaseConfigured || auth == null) {
      throw const AuthConfigurationException(
        'Firebase עדיין לא הוגדר עבור האפליקציה. אפשר להמשיך במצב מקומי ולהגדיר את Google בהמשך.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await auth.signInWithCredential(credential);
    final user = _toAppUser(userCredential.user);
    if (user == null) {
      throw const AuthConfigurationException('לא התקבל משתמש מ־Google.');
    }

    await disableLocalMode();
    return user;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google may not have an active local session.
    }
    await disableLocalMode();
  }

  @override
  Future<bool> isLocalModeEnabled() async {
    return _preferences.getBool(_localModeKey) ?? false;
  }

  @override
  Future<void> continueLocally() {
    return _preferences.setBool(_localModeKey, true);
  }

  @override
  Future<void> disableLocalMode() {
    return _preferences.remove(_localModeKey);
  }

  static AppUser? _toAppUser(User? user) {
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'משתמש MoveMate',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }
}
