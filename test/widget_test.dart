import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/services/export_service.dart';

class _FakeExport implements ExportService {
  final List<String> saved = [];

  @override
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3,
  }) async => Uint8List.fromList([1, 2, 3]);

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

void main() {
  testWidgets('pick a verse, toggle translation, open card, export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final export = _FakeExport();
    await tester.pumpWidget(SnippetApp(export: export));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Snippet'), findsWidgets);
    expect(find.byKey(const Key('passage-text')), findsOneWidget);
    expect(find.textContaining('only begotten Son'), findsOneWidget); // KJV

    await tester.tap(find.text('WEB'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('only born Son'), findsOneWidget); // WEB

    await tester.ensureVisible(find.byKey(const Key('create-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-card')));
    await tester.pumpAndSettle();
    expect(find.textContaining('John 3:16 · WEB'), findsOneWidget);

    await tester.tap(find.byKey(const Key('style-night')));
    await tester.tap(find.byKey(const Key('font-sans')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('export-png')));
    await tester.pumpAndSettle();
    expect(export.saved, ['snippet_john_3_16']);
  });
}
