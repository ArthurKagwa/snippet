import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_credential_stub.dart';

class FirebaseUserStub extends Fake implements User, UserInfo {
  String address = 'reader@example.com';
  bool verified = false;
  bool anonymous = false;
  String provider = EmailAuthProvider.PROVIDER_ID;
  FirebaseAuthException? reauthError;
  FirebaseAuthException? reloadError;
  FirebaseAuthException? verificationError;
  final actions = <String>[];
  AuthCredential? credential;
  void Function()? onReload;

  @override
  String get uid => 'user-1';

  @override
  String? get displayName => null;

  @override
  String? get email => address;

  @override
  bool get emailVerified => verified;

  @override
  bool get isAnonymous => anonymous;

  // This stub also implements the password provider's UserInfo.
  @override
  List<UserInfo> get providerData => [this];

  @override
  String get providerId => provider;

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    actions.add('reauth');
    this.credential = credential;
    if (reauthError case final error?) throw error;
    // The service only awaits this response; no credential fields are read.
    return FirebaseCredentialStub();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async => actions.add('verify:$newEmail');

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    actions.add('send-verification');
    if (verificationError case final error?) throw error;
  }

  @override
  Future<void> reload() async {
    actions.add('reload');
    if (reloadError case final error?) throw error;
    onReload?.call();
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    actions.add('token:$forceRefresh');
    return 'token';
  }
}
