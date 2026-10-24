import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';
import 'firebase_auth_error.dart';

/// [AuthService] backed by Firebase Auth, with Google and email/password
/// as sign-in providers. Client IDs come from google-services.json /
/// GoogleService-Info.plist, so nothing is hardcoded here.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  static AppUser? _toAppUser(User? u) => u == null
      ? null
      : AppUser(
          id: u.uid,
          displayName: u.displayName,
          email: u.email,
          isAnonymous: u.isAnonymous,
          emailVerified: u.emailVerified,
          usesPassword: u.providerData.any(
            (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
          ),
        );

  /// Runs [action], turning Firebase errors into [AuthException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error: ${e.code}');
      throw firebaseAuthError(e);
    }
  }

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  /// userChanges also fires when a profile changes (e.g. after linking).
  @override
  Stream<AppUser?> get authStateChanges => _auth.userChanges().map(_toAppUser);

  @override
  bool get supportsGoogleSignIn => _google.supportsAuthenticate();

  @override
  bool get supportsEmailSignIn => true;

  @override
  Future<AppUser> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return _toAppUser(result.user)!;
  }

  /// Runs the Google prompt; null when the user cancels it.
  Future<AuthCredential?> _googleCredential() async {
    await (_googleReady ??= _google.initialize());
    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return an ID token');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Returns null when the user cancels the Google prompt.
  @override
  Future<AppUser?> signInWithGoogle() async {
    final credential = await _googleCredential();
    if (credential == null) return null;

    // Upgrade a "this phone only" session in place so its uid is kept.
    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      try {
        result = await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') rethrow;
        result = await _auth.signInWithCredential(credential);
      }
    } else {
      result = await _auth.signInWithCredential(credential);
    }
    return _toAppUser(result.user);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _toAppUser(result.user)!;
      });

  /// Upgrades a "this phone only" session in place so its cards are kept.
  @override
  Future<AppUser> createAccountWithEmail(String email, String password) =>
      _guard(() async {
        final current = _auth.currentUser;
        final UserCredential result;
        if (current != null && current.isAnonymous) {
          result = await current.linkWithCredential(
            EmailAuthProvider.credential(
              email: email.trim(),
              password: password,
            ),
          );
        } else {
          result = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        }
        return _toAppUser(result.user)!;
      });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Match Firebase's enumeration-protected response on older projects.
      if (e.code != 'user-not-found') rethrow;
    }
  });

  User _emailUser() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.email == null) {
      throw const AuthException('Sign in to manage your email.');
    }
    return user;
  }

  @override
  Future<void> sendEmailVerification() => _guard(() async {
    final user = _emailUser();
    if (!user.emailVerified) await user.sendEmailVerification();
  });

  @override
  Future<void> changeEmail(String email, {String? password}) =>
      _guard(() async {
        final user = _emailUser();
        final address = email.trim();
        if (address.toLowerCase() == user.email!.toLowerCase()) {
          throw const AuthException('Enter a different email address.');
        }
        final usesPassword = user.providerData.any(
          (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
        );
        final AuthCredential credential;
        if (usesPassword) {
          if (password == null || password.isEmpty) {
            throw const AuthException('Enter your current password.');
          }
          credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
        } else {
          final googleCredential = await _googleCredential();
          if (googleCredential == null) {
            throw const AuthException(
              'Confirm with Google to change your email.',
            );
          }
          credential = googleCredential;
        }
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(address);
      });

  @override
  Future<AppUser?> refreshUser() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      // Refresh claims before reload publishes a verified profile. Library
      // listeners can then sync immediately with an email_verified token.
      await user.getIdToken(true);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if ({
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'invalid-user-token',
      }.contains(e.code)) {
        await signOut();
        throw const AuthException(
          'Your session ended. Sign in again to continue.',
        );
      }
      rethrow;
    }
    return currentUser;
  });

  @override
  Future<void> confirmPassword(String password) => _guard(() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  });

  @override
  Future<void> signOut() async {
    if (_googleReady != null) {
      try {
        await _google.signOut();
      } on GoogleSignInException {
        // Firebase sign-out below is what matters.
      }
    }
    await _auth.signOut();
  }

  /// Firebase only deletes accounts that signed in recently: email
  /// accounts call [confirmPassword] first, and Google accounts re-confirm
  /// with Google when asked to.
  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      final credential = await _googleCredential();
      if (credential == null) {
        throw StateError('Confirm with Google to delete your account');
      }
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    }
    await signOut();
  }
}
