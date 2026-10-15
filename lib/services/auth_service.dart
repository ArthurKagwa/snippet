import 'dart:async';

/// Minimal user model, independent of any auth SDK.
class AppUser {
  const AppUser({required this.id, this.displayName, this.isAnonymous = false});

  final String id;
  final String? displayName;
  final bool isAnonymous;
}

/// Optional login. The app is fully usable signed out.
///
/// Replace [LocalAuthService] with a Firebase-backed implementation once the
/// Firebase project exists (see README "Firebase setup").
abstract class AuthService {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;
  bool get supportsGoogleSignIn;

  Future<AppUser> signInAnonymously();
  Future<AppUser?> signInWithGoogle();
  Future<void> signOut();
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
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
