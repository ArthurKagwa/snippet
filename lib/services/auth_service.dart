import 'dart:async';

/// Minimal user model, independent of any auth SDK.
class AppUser {
  const AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.isAnonymous = false,
    this.usesPassword = false,
  });

  final String id;
  final String? displayName;
  final String? email;
  final bool isAnonymous;

  /// Signed in with email and password (not Google).
  final bool usesPassword;

  /// "DM" for "Daniel Mugisha"; empty when there is no name.
  String get initials {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }
}

/// A sign-in failure with a message that can be shown as is.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Optional login. The app is fully usable signed out.
///
/// Replace [LocalAuthService] with a Firebase-backed implementation once the
/// Firebase project exists (see README "Firebase setup").
abstract class AuthService {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;
  bool get supportsGoogleSignIn;
  bool get supportsEmailSignIn;

  Future<AppUser> signInAnonymously();
  Future<AppUser?> signInWithGoogle();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> createAccountWithEmail(String email, String password);
  Future<void> sendPasswordReset(String email);

  /// Re-checks an email account's password before a sensitive action such
  /// as [deleteAccount]; throws [AuthException] when it is wrong.
  Future<void> confirmPassword(String password);
  Future<void> signOut();

  /// Permanently deletes the account (its data should be removed first).
  Future<void> deleteAccount();
}

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
  Future<void> confirmPassword(String password) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() => signOut(); // nothing stored remotely
}
