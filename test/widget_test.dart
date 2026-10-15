import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/export_service.dart';

class _FakeExport implements ExportService {
  final List<String> saved = [];
  final List<double> ratios = [];

  @override
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3,
  }) async {
    ratios.add(pixelRatio * boundary.size.width);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> saveToGallery(Uint8List png, {required String name}) async =>
      saved.add(name);

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}
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

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    export = _FakeExport();
    store = MemoryJsonStore();
    await tester.pumpWidget(SnippetApp(export: export, store: store));
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

  testWidgets('saving asks to sign in; Not now keeps the card', (
    tester,
  ) async {
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
  });

  testWidgets('empty library offers to pick a verse', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('library-button')));
    await _settle(tester);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pick-a-verse')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a verse'), findsOneWidget);
  });
}
