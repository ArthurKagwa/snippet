import 'dart:async';

import 'package:snippet/services/auth_service.dart';

/// Email accounts held in memory; one known password per address.
class TestEmailAuth extends LocalAuthService {
  TestEmailAuth(this.accounts) : verifiedEmails = accounts.keys.toSet();

  final Map<String, String> accounts;
  final Set<String> verifiedEmails;
  final _changes = StreamController<AppUser?>.broadcast();
  final List<String> resets = [];
  int verifications = 0;
  int refreshes = 0;
  AuthException? verificationFailure;
  AuthException? resetFailure;
  AuthException? refreshFailure;
  AppUser? refreshedUser;
  Completer<void>? verificationGate;
  final List<String> emailChanges = [];

  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => _changes.stream;

  @override
  bool get supportsGoogleSignIn => true;

  @override
  bool get supportsEmailSignIn => true;

  AppUser _set(String email) {
    setUser(
      AppUser(
        id: email,
        email: email,
        usesPassword: true,
        emailVerified: verifiedEmails.contains(email),
      ),
    );
    return _user!;
  }

  void setUser(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<AppUser> signInAnonymously() => throw UnimplementedError();

  @override
  Future<AppUser?> signInWithGoogle() async => null;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    if (accounts[email.trim()] != password) {
      throw const AuthException('That email and password do not match.');
    }
    return _set(email.trim());
  }

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) async {
    if (accounts.containsKey(email.trim())) {
      throw const AuthException('That email already has an account.');
    }
    accounts[email.trim()] = password;
    return _set(email.trim());
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (resetFailure case final failure?) throw failure;
    resets.add(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    verifications++;
    await verificationGate?.future;
    if (verificationFailure case final failure?) throw failure;
  }

  @override
  Future<AppUser?> refreshUser() async {
    refreshes++;
    if (refreshFailure case final failure?) throw failure;
    if (refreshedUser != null) {
      _user = refreshedUser;
      _changes.add(_user);
    }
    return _user;
  }

  @override
  Future<void> changeEmail(String email, {String? password}) async {
    if (accounts[_user?.email] != password) {
      throw const AuthException('That email and password do not match.');
    }
    emailChanges.add(email);
  }

  @override
  Future<void> confirmPassword(String password) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() => signOut();
}
