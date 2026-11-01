import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/services/auth_service.dart';
import 'package:snippet/services/firebase_auth_service.dart';

import 'support/firebase_auth_stub.dart';
import 'support/firebase_user_stub.dart';
import 'support/google_sign_in_stub.dart';

void main() {
  late FirebaseAuthStub firebase;
  late FirebaseUserStub user;
  late FirebaseAuthService auth;
  final authError = isA<AuthException>();

  setUp(() {
    user = FirebaseUserStub();
    firebase = FirebaseAuthStub()..user = user;
    auth = FirebaseAuthService(auth: firebase);
  });

  test('reset trims email and does not reveal missing accounts', () async {
    firebase.resetError = FirebaseAuthException(code: 'user-not-found');
    await auth.sendPasswordReset(' missing@example.com ');
    expect(firebase.resetEmail, 'missing@example.com');
    firebase.resetError = FirebaseAuthException(code: 'network-request-failed');
    await expectLater(auth.sendPasswordReset('a@b.co'), throwsA(authError));
  });

  test(
    'email change requires the current password before sending a link',
    () async {
      await expectLater(
        auth.changeEmail('new@example.com'),
        throwsA(authError),
      );
      expect(user.actions, isEmpty);
      await auth.changeEmail(' new@example.com ', password: 'Psalm4610');
      expect(user.actions, ['reauth', 'verify:new@example.com']);
      expect(
        (user.credential as EmailAuthCredential).email,
        'reader@example.com',
      );
      expect((user.credential as EmailAuthCredential).password, 'Psalm4610');
      expect(auth.currentUser?.email, 'reader@example.com');
    },
  );

  test('wrong credentials never send a change link', () async {
    user.reauthError = FirebaseAuthException(code: 'wrong-password');
    await expectLater(
      auth.changeEmail('new@example.com', password: 'wrong'),
      throwsA(authError),
    );
    expect(user.actions, ['reauth']);
  });

  test(
    'Google email changes require a successful Google confirmation',
    () async {
      user.provider = GoogleAuthProvider.PROVIDER_ID;
      final google = GoogleSignInStub()..canceled = true;
      auth = FirebaseAuthService(auth: firebase, google: google);
      await expectLater(
        auth.changeEmail('new@example.com'),
        throwsA(authError),
      );
      expect(user.actions, isEmpty);
      google.canceled = false;
      await auth.changeEmail('new@example.com');
      expect(google.prompts, 2);
      expect(user.actions, ['reauth', 'verify:new@example.com']);
      expect(user.credential?.providerId, GoogleAuthProvider.PROVIDER_ID);
    },
  );

  test(
    'unchanged addresses and anonymous users cannot request changes',
    () async {
      await expectLater(
        auth.changeEmail('READER@example.com', password: 'Psalm4610'),
        throwsA(authError),
      );
      user.anonymous = true;
      await expectLater(
        auth.changeEmail('new@example.com', password: 'Psalm4610'),
        throwsA(authError),
      );
      await expectLater(auth.sendEmailVerification(), throwsA(authError));
      expect(user.actions, isEmpty);
      firebase.user = null;
      await expectLater(auth.sendEmailVerification(), throwsA(authError));
    },
  );

  test('verified users do not receive another verification email', () async {
    await auth.sendEmailVerification();
    user.verified = true;
    await auth.sendEmailVerification();
    expect(user.actions, ['send-verification']);
    expect(auth.currentUser?.emailVerified, isTrue);
    expect((await auth.authStateChanges.first)?.emailVerified, isTrue);
  });

  test('verification delivery errors become readable auth errors', () async {
    user.verificationError = FirebaseAuthException(code: 'too-many-requests');
    await expectLater(
      auth.sendEmailVerification(),
      throwsA(authError.having((e) => e.message, 'message', contains('Wait'))),
    );
  });

  test(
    'refresh reads the updated profile and refreshes token claims',
    () async {
      user.onReload = () {
        user.verified = true;
        user.address = 'new@example.com';
      };
      final updated = await auth.refreshUser();
      expect(updated?.emailVerified, isTrue);
      expect(updated?.email, 'new@example.com');
      expect(updated?.id, 'user-1');
      expect(user.actions, ['token:true', 'reload']);
    },
  );

  test(
    'refresh signs out a revoked session but preserves an offline one',
    () async {
      user.reloadError = FirebaseAuthException(code: 'network-request-failed');
      await expectLater(auth.refreshUser(), throwsA(authError));
      expect(firebase.signOuts, 0);
      expect(auth.currentUser, isNotNull);
      user.reloadError = FirebaseAuthException(code: 'user-token-expired');
      await expectLater(auth.refreshUser(), throwsA(authError));
      expect(firebase.signOuts, 1);
      expect(auth.currentUser, isNull);
      expect(await auth.refreshUser(), isNull);
    },
  );
}
