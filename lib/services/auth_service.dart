import 'app_user.dart';

export 'app_user.dart';
export 'auth_exception.dart';
export 'local_auth_service.dart';

/// Optional login. The app is fully usable signed out.
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
  Future<void> sendEmailVerification();

  /// Reauthenticates, then sends a link to [email]. The address changes only
  /// after that link is verified. Password accounts must supply [password].
  Future<void> changeEmail(String email, {String? password});

  /// Reloads the profile after an email action completed in the browser.
  Future<AppUser?> refreshUser();

  /// Re-checks an email account's password before a sensitive action such
  /// as [deleteAccount]; throws [AuthException] when it is wrong.
  Future<void> confirmPassword(String password);
  Future<void> signOut();

  /// Permanently deletes the account (its data should be removed first).
  Future<void> deleteAccount();
}
