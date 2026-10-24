import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FirebaseAuthStub extends Fake implements FirebaseAuth {
  User? user;
  String? resetEmail;
  FirebaseAuthException? resetError;
  int signOuts = 0;

  @override
  User? get currentUser => user;

  @override
  Stream<User?> userChanges() => Stream.value(user);

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmail = email;
    if (resetError case final error?) throw error;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    user = null;
  }
}
