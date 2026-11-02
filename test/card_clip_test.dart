import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/cards/card_measure.dart';
import 'package:snippet/cards/card_shape.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/card_style_spec.dart';
import 'package:snippet/cards/fleuron.dart';
import 'package:snippet/cards/quote_card.dart';
import 'package:snippet/cards/verse_scale.dart';
import 'package:snippet/core/app_theme.dart';
import 'package:snippet/data/bible_models.dart';
import 'package:snippet/data/bible_repository.dart';

void main() {
  tearDown(() => CardCatalog.apply(CardStyleOverrides.none));

  testWidgets('long passages stay unclipped on every offered size', (
    tester,
  ) async {
    final example = File('remote_card_styles.example.json').readAsStringSync();
    CardCatalog.apply(CardStyleOverrides.parse(example));
    const passages = [('web', 'JOH', 3, 16, 21), ('kjv', 'EST', 8, 9, 9)];
    for (final passage in passages) {
      final (translation, book, chapter, start, end) = passage;
      final content = _passage(translation, book, chapter, start, end);
      for (final style in CardCatalog.styles) {
        final shapes = VerseScales.exportShapes(style, content);
        expect(shapes, isNotEmpty, reason: style.id);
        for (final shape in shapes) {
          await _pump(tester, content, style, shape);
          final why = '${content.reference} ${style.id} ${shape.name}';
          expect(tester.takeException(), isNull, reason: why);
          final verse = _verse(tester, content.text);
          final painted = _textHeight(verse);
          expect(
            painted,
            lessThanOrEqualTo(
              verse.constraints.maxHeight + CardMeasure.epsilon,
            ),
            reason: why,
          );
          final fleuron = find.byType(Fleuron);
          if (fleuron.evaluate().isNotEmpty) {
            final mark = tester.getRect(fleuron);
            final top = verse.localToGlobal(Offset.zero).dy;
            expect(mark.bottom, lessThanOrEqualTo(top + 0.5), reason: why);
          }
        }
      }
    }
  });

  testWidgets('the vigil ornament is drawn, not a missing glyph', (
    tester,
  ) async {
    final style = CardCatalog.byId('vigil');
    const content = CardContent(
      text: 'Jesus wept.',
      reference: 'John 11:35',
      translation: 'KJV',
    );
    await _pump(tester, content, style, CardShape.story);
    expect(tester.takeException(), isNull);
    final fleuron = tester.widget<Fleuron>(find.byType(Fleuron));
    expect(fleuron.extent, greaterThan(8));
    expect(find.textContaining('❧'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  CardContent content,
  CardStyleSpec style,
  CardShape shape,
) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cobaltSwipe(),
      home: Center(
        child: SizedBox(
          width: CardShape.designWidth,
          child: QuoteCard(
            content: content,
            style: style,
            variant: style.variants.first,
            shape: shape,
            showMark: true,
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _verse(WidgetTester tester, String text) {
  final wanted = text.trim();
  final upper = wanted.toUpperCase();
  RenderParagraph? verse;
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      final plain = node.text.toPlainText().trim();
      if (plain == wanted || plain == upper) verse = node;
    }
    node.visitChildren(visit);
  }

  visit(tester.renderObject(find.byType(QuoteCard)));
  expect(verse, isNotNull);
  return verse!;
}

double _textHeight(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: TextScaler.noScaling,
    maxLines: paragraph.maxLines,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
}

CardContent _passage(
  String translation,
  String bookId,
  int chapter,
  int start,
  int end,
) {
  final raw = File('assets/bibles/$translation.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final book = (json['books'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((b) => b['id'] == bookId);
  final verses =
      (book['chapters'] as List<dynamic>)[chapter - 1] as List<dynamic>;
  return CardContent(
    text: verses.sublist(start - 1, end).join(' '),
    reference: BibleRepository.formatReference(
      book['name'] as String,
      VerseRange(
        bookId: bookId,
        chapter: chapter,
        startVerse: start,
        endVerse: end,
      ),
    ),
    translation: translation.toUpperCase(),
  );
}
