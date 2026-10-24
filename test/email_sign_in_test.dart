import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/auth_service.dart';

import 'support/test_email_auth.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
}

void main() {
  late TestEmailAuth auth;
  late MemoryJsonStore store;

  setUp(rootBundle.clear);

  Future<void> openEmailForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    auth = TestEmailAuth({'review@example.com': 'secret1'});
    store = MemoryJsonStore();
    await tester.pumpWidget(
      SnippetApp(key: UniqueKey(), auth: auth, store: store),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-sign-in')));
    await tester.pumpAndSettle();
  }

  testWidgets('a wrong password stays in the form; the right one saves', (
    tester,
  ) async {
    await openEmailForm(tester);
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'review@example.com',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'nope');
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    expect(find.text('That email and password do not match.'), findsOneWidget);
    expect(auth.currentUser, isNull);

    await tester.enterText(find.byKey(const Key('password-field')), 'secret1');
    await tester.tap(find.byKey(const Key('email-submit')));
    await _settle(tester);
    expect(find.text('Keep it in your library'), findsNothing);
    expect(auth.currentUser?.email, 'review@example.com');
    expect(await store.read('library'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('creating an account needs a strong, confirmed password', (
    tester,
  ) async {
    await openEmailForm(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.byKey(const Key('confirm-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email-field')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('password-field')), 'abc123');
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a password that ticks every point above.'),
      findsOneWidget,
    );
    expect(auth.accounts.containsKey('a@b.co'), isFalse);

    await tester.enterText(
      find.byKey(const Key('password-field')),
      'Psalm4610',
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.check_circle_rounded,
      ),
      findsNWidgets(3),
    );
    await tester.enterText(find.byKey(const Key('confirm-field')), 'Psalm461');
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(auth.accounts.containsKey('a@b.co'), isFalse);

    await tester.enterText(find.byKey(const Key('confirm-field')), 'Psalm4610');
    await tester.tap(find.byKey(const Key('email-submit')));
    await _settle(tester);
    expect(auth.accounts['a@b.co'], 'Psalm4610');
    expect(auth.currentUser?.email, 'a@b.co');
    expect(auth.verifications, 1);
    expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
    expect(await store.read('library'), isNull);
    await tester.tap(find.byKey(const Key('verification-check')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not verified yet.'), findsOneWidget);
    expect(await store.read('library'), isNull);
    auth.refreshedUser = const AppUser(
      id: 'a@b.co',
      email: 'a@b.co',
      usesPassword: true,
      emailVerified: true,
    );
    await tester.tap(find.byKey(const Key('verification-check')));
    await _settle(tester);
    expect(find.byKey(const Key('email-verification-step')), findsNothing);
    expect(await store.read('library'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Forgot password sends a reset to the typed email', (
    tester,
  ) async {
    await openEmailForm(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email above first.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('email-field')),
      'review@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(auth.resets, ['review@example.com']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
  testWidgets(
    'failed verification delivery keeps setup pending and can be retried',
    (tester) async {
      await openEmailForm(tester);
      auth.verificationFailure = const AuthException('No connection.');
      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email-field')), 'new@b.co');
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'Psalm4610',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-field')),
        'Psalm4610',
      );
      await tester.tap(find.byKey(const Key('email-submit')));
      await _settle(tester);
      expect(auth.currentUser?.email, 'new@b.co');
      expect(auth.verifications, 1);
      expect(find.byKey(const Key('email-submit')), findsNothing);
      expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
      expect(await store.read('library'), isNull);
      await tester.tap(find.byKey(const Key('verification-resend')));
      await tester.pumpAndSettle();
      expect(find.text('No connection.'), findsOneWidget);
      auth.verificationFailure = null;
      await tester.tap(find.byKey(const Key('verification-resend')));
      await tester.pumpAndSettle();
      expect(auth.verifications, 3);
      expect(find.textContaining('Verification link sent.'), findsOneWidget);
      expect(await store.read('library'), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
}
