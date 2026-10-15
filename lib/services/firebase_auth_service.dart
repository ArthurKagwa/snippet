import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// [AuthService] backed by Firebase Auth, with Google as the sign-in
/// provider. Client IDs come from google-services.json /
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
        );

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  /// userChanges also fires when a profile changes (e.g. after linking).
  @override
  Stream<AppUser?> get authStateChanges => _auth.userChanges().map(_toAppUser);

  @override
  bool get supportsGoogleSignIn => _google.supportsAuthenticate();

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

  /// Firebase only deletes accounts that signed in recently, so this
  /// re-confirms with Google when asked to.
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
