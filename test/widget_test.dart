import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/features/library/saved_card_tile.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/export_service.dart';

class _FakeExport implements ExportService {
  final List<String> saved = [];
  final List<double> ratios = [];

  /// When set, saving waits on it, so a test can tap while work is pending.
  Completer<void>? gate;

  @override
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3,
  }) async {
    ratios.add(pixelRatio * boundary.size.width);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> saveToGallery(Uint8List png, {required String name}) async {
    saved.add(name);
    await gate?.future;
  }

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}
}

class _FakeContent implements ContentConfigService {
  _FakeContent(this.announcement);

  final String announcement;

  @override
  Future<ContentConfig> load() async => ContentConfig(
    featuredVerses: defaultContentConfig.featuredVerses,
    announcement: announcement,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeExport export;
  late MemoryJsonStore store;

  // rootBundle caches futures created in a previous test's fake-async zone,
  // which never complete in the next test.
  setUp(rootBundle.clear);

  Future<void> boot(
    WidgetTester tester, {
    ContentConfigService? contentConfig,
    MemoryJsonStore? reuseStore,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    export = _FakeExport();
    store = reuseStore ?? MemoryJsonStore();
    await tester.pumpWidget(
      SnippetApp(
        // A new key relaunches the app instead of updating it.
        key: UniqueKey(),
        export: export,
        store: store,
        contentConfig: contentConfig,
      ),
    );
    await _settle(tester);
  }

  testWidgets('home shows the picked verse and toggles translation', (
    tester,
  ) async {
    await boot(tester);

    expect(find.byKey(const Key('passage-text')), findsOneWidget);
    expect(find.textContaining('among the heathen'), findsOneWidget); // KJV

    await tester.tap(find.text('WEB'));
    await _settle(tester);
    expect(find.textContaining('among the nations'), findsOneWidget); // WEB

    // The Styles tab previews whatever is picked on Home.
    await tester.tap(find.byKey(const Key('nav-styles')));
    await tester.pumpAndSettle();
    expect(find.text('Vigil'), findsOneWidget);
    expect(find.text('WEB'), findsOneWidget); // translation chip
  });

  testWidgets('swipe styles, export a story PNG', (tester) async {
    await boot(tester);

    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    expect(find.text('Vigil'), findsOneWidget);
    expect(find.text('Gilt'), findsOneWidget);

    // Up: next style.
    await tester.fling(
      find.byKey(const Key('style-pager')),
      const Offset(0, -400),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Riso Loud'), findsOneWidget);

    // Sideways: next colourway.
    await tester.fling(
      find.byKey(const Key('card-riso-pink')),
      const Offset(-300, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('export-card')));
    await tester.pumpAndSettle();
    expect(find.text('Share it'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shape-story')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-image')));
    await tester.pumpAndSettle();
    expect(export.saved, ['snippet_psalm_46_10_story']);
    expect(export.ratios.single, closeTo(1080, 0.5));
  });

  testWidgets('saving asks to sign in; Not now keeps the card', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
    expect(find.text('Keep it in your library'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Keep it in your library'), findsNothing);
    expect(find.text('Vigil'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('local-sign-in')));
    await _settle(tester);
    expect(find.text('Saved to your library'), findsOneWidget);
    expect(await store.read('library'), hasLength(1));

    // The toast has a View action but still goes away on its own.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your library'), findsNothing);
  });

  testWidgets('a double tap on Save image exports once', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export-card')));
    await tester.pumpAndSettle();

    export.gate = Completer<void>();
    await tester.tap(find.byKey(const Key('save-image')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-image')));
    await tester.tap(find.byKey(const Key('share-image')));
    await tester.pump();
    expect(export.saved, hasLength(1));

    export.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('home has one main action, distinct from the daily verse', (
    tester,
  ) async {
    await boot(tester);
    expect(find.text('Make a card'), findsOneWidget);
    expect(find.text('Use this verse'), findsOneWidget);
    expect(find.text('Preview'), findsNothing);
  });

  testWidgets('home shows an announcement until it is dismissed', (
    tester,
  ) async {
    const message = 'New styles this week';
    final text = find.byKey(const Key('announcement-text'));

    await boot(tester);
    expect(text, findsNothing); // Bundled content has none.

    await boot(tester, contentConfig: _FakeContent(message));
    expect(find.text(message), findsOneWidget);
    expect(find.text('Make a card'), findsOneWidget);

    await tester.tap(find.byKey(const Key('announcement-dismiss')));
    await tester.pumpAndSettle();
    expect(text, findsNothing);

    // Stays dismissed after a relaunch...
    await boot(tester, contentConfig: _FakeContent(message), reuseStore: store);
    expect(text, findsNothing);

    // ...but a new message shows.
    await boot(
      tester,
      contentConfig: _FakeContent('Daily reminders are here'),
      reuseStore: store,
    );
    expect(find.text('Daily reminders are here'), findsOneWidget);
  });

  testWidgets('profile offers sign-in, never sign-out, without an account', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    // Signed out.
    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('sign-out')), findsNothing);
    expect(find.byKey(const Key('profile-delete-account')), findsNothing);

    // "This phone only": no account to sign out of or delete.
    await tester.tap(find.byKey(const Key('profile-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('local-sign-in')));
    await _settle(tester);
    expect(find.text('On this phone'), findsOneWidget);
    expect(find.byKey(const Key('profile-sign-in')), findsNothing);
    expect(find.byKey(const Key('sign-out')), findsNothing);
    expect(find.byKey(const Key('profile-delete-account')), findsNothing);
    expect(find.byKey(const Key('profile-clear-cards')), findsOneWidget);
  });

  testWidgets('empty library offers to pick a verse', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('nav-saved')));
    await _settle(tester);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pick-a-verse')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a verse'), findsOneWidget);
  });

  testWidgets('picking in All styles lands on that style', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    expect(find.text('Vigil'), findsOneWidget);

    await tester.tap(find.byKey(const Key('all-styles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('style-tile-riso')));
    // Mid-flight: the tile is on its way into the swipe card.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('All styles'), findsNothing);
    expect(find.text('Riso Loud'), findsOneWidget);
  });

  testWidgets('removing the last saved card fades to the empty state', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('swipe-styles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('local-sign-in')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-saved')));
    await _settle(tester);
    expect(find.byType(SavedCardTile), findsOneWidget);

    await tester.longPress(find.byType(SavedCardTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    // The tile plays its exit before the card is deleted.
    await tester.pump(const Duration(milliseconds: 90));
    expect(await store.read('library'), hasLength(1));
    await tester.pump(const Duration(milliseconds: 120));
    await _settle(tester);

    expect(await store.read('library'), isEmpty);
    expect(find.byType(SavedCardTile), findsNothing);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });
}
