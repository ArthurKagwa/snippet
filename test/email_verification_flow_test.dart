import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/auth_service.dart';

import 'support/test_email_auth.dart';

void main() {
  late TestEmailAuth auth;
  late MemoryJsonStore store;
  const verified = AppUser(
    id: 'reader@example.com',
    email: 'reader@example.com',
    usesPassword: true,
    emailVerified: true,
  );
  setUp(rootBundle.clear);

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester, {bool restored = true}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    auth = TestEmailAuth({'reader@example.com': 'Psalm4610'})
      ..verifiedEmails.clear();
    if (restored) await auth.signInWithEmail('reader@example.com', 'Psalm4610');
    store = MemoryJsonStore();
    await tester.pumpWidget(SnippetApp(auth: auth, store: store));
    await settle(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
  }

  testWidgets('dismissing verification cannot bypass it on the next save', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
    expect(await store.read('library'), isNull);
    await tester.tap(find.byKey(const Key('verification-not-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
    expect(await store.read('library'), isNull);
    auth.refreshFailure = const AuthException('No connection.');
    await tester.tap(find.byKey(const Key('verification-check')));
    await tester.pumpAndSettle();
    expect(find.text('No connection.'), findsOneWidget);
    expect(await store.read('library'), isNull);
    auth.refreshFailure = null;
    auth.refreshedUser = verified;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.byKey(const Key('email-verification-step')), findsNothing);
    expect(await store.read('library'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('unverified sign-in stays pending and can switch accounts', (
    tester,
  ) async {
    await boot(tester, restored: false);
    await tester.tap(find.byKey(const Key('email-sign-in')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'Psalm4610',
    );
    await tester.tap(find.byKey(const Key('email-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
    expect(await store.read('library'), isNull);
    await tester.tap(find.byKey(const Key('verification-sign-out')));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
    expect(find.byKey(const Key('email-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('email-verification-step')), findsNothing);
  });

  testWidgets('Saved offers a way to finish setup after dismissal', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('verification-not-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-saved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-verify-email')));
    // The entry button stays busy until the verification sheet is closed.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('email-verification-step')), findsOneWidget);
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('verification-not-now')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('verification-not-now')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-verification-step')), findsNothing);
  });
}
