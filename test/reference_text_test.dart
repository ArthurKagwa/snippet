import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/cards/card_shape.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/quote_card.dart';
import 'package:snippet/cards/verse_reference.dart';

/// The long book names, plus a three-digit reference and a range.
const _references = [
  'John 3:16',
  'Psalm 119:176',
  'Romans 8:28',
  'Philippians 4:13',
  'Ecclesiastes 3:1',
  'Lamentations 3:22',
  '1 Corinthians 13:4',
  '2 Thessalonians 3:3',
  '1 Thessalonians 5:16',
  'Song of Solomon 1:1',
  'Song of Solomon 1:1–3',
];

CardContent _content(String reference) => CardContent(
  text:
      'Be still, and know that I am God: I will be exalted among the '
      'heathen, I will be exalted in the earth.',
  reference: reference,
  translation: 'KJV',
);

/// Every paragraph on screen, with the box it was given.
Iterable<RenderParagraph> _paragraphs(WidgetTester tester) sync* {
  final found = <RenderParagraph>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) found.add(node);
    node.visitChildren(visit);
  }

  visit(tester.renderObject(find.byType(QuoteCard)));
  yield* found;
}

/// How tall [p]'s text really is in the width it was laid out at.
double _textHeight(RenderParagraph p) {
  final painter = TextPainter(
    text: p.text,
    textAlign: p.textAlign,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: p.maxLines,
  )..layout(maxWidth: p.size.width);
  final height = painter.height;
  painter.dispose();
  return height;
}

void main() {
  tearDown(() => CardCatalog.apply(CardStyleOverrides.none));

  group('CardContent splits a reference', () {
    test('book name from chapter and verse', () {
      for (final (reference, book, numbers) in [
        ('John 3:16', 'John', '3:16'),
        ('Psalm 119:176', 'Psalm', '119:176'),
        ('1 Thessalonians 5:16', '1 Thessalonians', '5:16'),
        ('Song of Solomon 1:1', 'Song of Solomon', '1:1'),
        ('Song of Solomon 1:1–3', 'Song of Solomon', '1:1–3'),
      ]) {
        final content = _content(reference);
        expect(content.referenceBook, book, reason: reference);
        expect(content.referenceNumbers, numbers, reason: reference);
      }
    });

    test('a reference with no chapter:verse stays whole', () {
      const content = CardContent(
        text: 'x',
        reference: 'Jude',
        translation: 'KJV',
      );
      expect(content.referenceBook, 'Jude');
      expect(content.referenceNumbers, isEmpty);
    });
  });

  testWidgets('the chapter and verse survive every book name', (tester) async {
    final example = File('remote_card_styles.example.json').readAsStringSync();
    CardCatalog.apply(CardStyleOverrides.parse(example));
    final style = CardCatalog.byId('highlight');

    for (final reference in _references) {
      final content = _content(reference);
      for (final shape in CardShape.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: CardShape.designWidth,
                child: QuoteCard(
                  content: content,
                  style: style,
                  variant: style.variants.first,
                  shape: shape,
                ),
              ),
            ),
          ),
        );
        final why = '$reference ${shape.name}';
        expect(tester.takeException(), isNull, reason: why);

        // The reference is drawn whole, on one line or two.
        final drawn = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(VerseReference),
                matching: find.byType(Text),
              ),
            )
            .single
            .data!;
        expect(
          drawn.replaceAll('\n', ' '),
          reference.toUpperCase(),
          reason: why,
        );
        expect(drawn.split('\n').length, lessThanOrEqualTo(2), reason: why);

        // And nothing on the card is taller than the box holding it, which
        // is how the chapter:verse used to get clipped away.
        for (final paragraph in _paragraphs(tester)) {
          expect(
            _textHeight(paragraph),
            lessThanOrEqualTo(paragraph.size.height + 0.5),
            reason: '$why: ${paragraph.text.toPlainText()}',
          );
        }
      }
    }
  });

  testWidgets('a fitted line is measured with the style it is painted in', (
    tester,
  ) async {
    // The ambient Material text style adds letter spacing that the card's
    // own style leaves unset; fitting has to allow for it.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(bodyMedium: TextStyle(letterSpacing: 4)),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 40,
              child: VerseReference(
                reference: 'Song of Solomon 1:1',
                upper: true,
                size: 31,
                minSize: 8,
                styleFor: (size) => TextStyle(fontSize: size, height: 1.05),
              ),
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.byType(Text));
    expect(paragraph.text.toPlainText(), contains('1:1'));
    expect(_textHeight(paragraph), lessThanOrEqualTo(40.5));
  });
}
