import 'dart:async';

import 'auth_service.dart';

/// Offline stand-in: anonymous sign-in works locally, Google is unavailable.
class LocalAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  bool get supportsGoogleSignIn => false;

  @override
  bool get supportsEmailSignIn => false;

  @override
  Future<AppUser> signInAnonymously() async {
    final user =
        _user ??
        AppUser(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          isAnonymous: true,
        );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async => null; // not configured yet

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      throw const AuthException('Email sign-in is not set up in this build.');

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) =>
      throw const AuthException('Email sign-in is not set up in this build.');

  @override
  Future<void> sendPasswordReset(String email) =>
      throw const AuthException('Email sign-in is not set up in this build.');

  @override
  Future<void> sendEmailVerification() =>
      throw const AuthException('Email sign-in is not set up in this build.');

  @override
  Future<void> changeEmail(String email, {String? password}) =>
      throw const AuthException('Email sign-in is not set up in this build.');

  @override
  Future<AppUser?> refreshUser() async => _user;

  @override
  Future<void> confirmPassword(String password) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() => signOut(); // nothing stored remotely
}
