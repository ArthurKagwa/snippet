import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/auth_service.dart';

import 'support/test_email_auth.dart';

void main() {
  late TestEmailAuth auth;

  setUp(rootBundle.clear);

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    auth = TestEmailAuth({'reader@example.com': 'Psalm4610'});
    auth.verifiedEmails.clear();
    await auth.signInWithEmail('reader@example.com', 'Psalm4610');
    await tester.pumpWidget(SnippetApp(auth: auth, store: MemoryJsonStore()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('reset failures can be retried from Profile', (tester) async {
    await openProfile(tester);
    auth.resetFailure = const AuthException('No connection.');
    await tester.tap(find.byKey(const Key('account-reset')));
    await tester.pumpAndSettle();
    expect(find.text('No connection.'), findsOneWidget);
    expect(auth.resets, isEmpty);
    auth.resetFailure = null;
    await tester.tap(find.byKey(const Key('account-reset')));
    await tester.pumpAndSettle();
    expect(auth.resets, ['reader@example.com']);
    expect(find.text('No connection.'), findsNothing);
    expect(
      find.text('If that email has an account, a reset link is on its way.'),
      findsOneWidget,
    );
  });

  testWidgets('verification blocks repeat taps and reports delivery errors', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.text('Not verified'), findsOneWidget);
    auth.verificationGate = Completer<void>();
    await tester.tap(find.byKey(const Key('account-verify')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-verify')));
    await tester.tap(find.byKey(const Key('account-reset')));
    expect(auth.verifications, 1);
    expect(auth.resets, isEmpty);
    auth.verificationFailure = const AuthException('Too many tries.');
    auth.verificationGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Too many tries.'), findsOneWidget);
    auth.verificationFailure = null;
    await tester.tap(find.byKey(const Key('account-verify')));
    await tester.pumpAndSettle();
    expect(auth.verifications, 2);
    expect(
      find.text('Verification link sent. Check your inbox and spam folder.'),
      findsOneWidget,
    );
  });

  testWidgets('returning from an email link refreshes verification', (
    tester,
  ) async {
    await openProfile(tester);
    final before = auth.refreshes;
    auth.refreshedUser = const AppUser(
      id: 'reader@example.com',
      email: 'reader@example.com',
      usesPassword: true,
      emailVerified: true,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(auth.refreshes, greaterThan(before));
    expect(find.text('Verified'), findsOneWidget);
    expect(find.byKey(const Key('account-verify')), findsNothing);
  });

  testWidgets(
    'email change validates, reauthenticates and waits for the link',
    (tester) async {
      await openProfile(tester);
      await tester.tap(find.byKey(const Key('account-change')));
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('change-email-submit'));
      final email = find.byKey(const Key('new-email-field'));
      final password = find.byKey(const Key('current-password-field'));
      await tester.enterText(email, 'invalid');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Check the new email address.'), findsOneWidget);
      await tester.enterText(email, 'READER@example.com');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Enter a different email address.'), findsOneWidget);
      await tester.enterText(email, ' new@example.com ');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Enter your current password.'), findsOneWidget);
      await tester.enterText(password, 'wrong');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('That email and password do not match.'),
        findsOneWidget,
      );
      expect(auth.emailChanges, isEmpty);
      await tester.enterText(password, 'Psalm4610');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(auth.emailChanges, ['new@example.com']);
      expect(auth.currentUser?.email, 'reader@example.com');
      expect(submit, findsNothing);
      expect(
        find.textContaining('Waiting for verification at new@example.com'),
        findsOneWidget,
      );

      auth.refreshedUser = const AppUser(
        id: 'reader@example.com',
        email: 'new@example.com',
        usesPassword: true,
        emailVerified: true,
      );
      await tester.tap(find.byKey(const Key('account-refresh')));
      await tester.pumpAndSettle();
      expect(find.text('Your email has been updated.'), findsOneWidget);
      expect(find.textContaining('Waiting for verification at'), findsNothing);
      expect(find.text('new@example.com'), findsOneWidget);
    },
  );
}
