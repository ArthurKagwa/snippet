import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/cards/card_palette.dart';
import 'package:snippet/cards/card_shape.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/card_style_spec.dart';
import 'package:snippet/cards/quote_card.dart';
import 'package:snippet/cards/verse_reference.dart';
import 'package:snippet/cards/verse_scale.dart';

const _short = 'Jesus wept.';

/// A verse long enough to leave the short bucket without being a paragraph.
String _repeat(int words) => List.filled(words, 'beloved').join(' ');

String _ofLength(int characters) {
  final text = _repeat(characters);
  return text.length <= characters ? text : text.substring(0, characters);
}

String _until(VerseBucket target) {
  for (var words = 1; words < 4000; words += words < 30 ? 1 : 8) {
    final text = _repeat(words);
    if (VerseScales.bucketOf(text) == target) return text;
  }
  fail('no verse landed in $target');
}

CardContent _content(String reference, {String text = _short}) =>
    CardContent(text: text, reference: reference, translation: 'KJV');

void main() {
  tearDown(() {
    CardCatalog.apply(CardStyleOverrides.none);
    VerseScales.byId.remove('cramped');
  });

  test('length buckets grow with the verse and only the longest is story', () {
    expect(VerseScales.bucketOf(_short), VerseBucket.short);
    expect(VerseScales.bucketOf(''), VerseBucket.short);

    final medium = _until(VerseBucket.medium);
    final long = _until(VerseBucket.long);
    final longest = _until(VerseBucket.longest);
    expect(VerseScales.bucketOf(medium), VerseBucket.medium);
    expect(VerseScales.bucketOf(long), VerseBucket.long);
    expect(VerseScales.bucketOf(longest), VerseBucket.longest);

    expect(
      VerseScales.lineCount(medium),
      greaterThan(VerseScales.lineCount(_short)),
    );
    expect(
      VerseScales.lineCount(long),
      greaterThan(VerseScales.lineCount(medium)),
    );
    expect(
      VerseScales.lineCount(longest),
      greaterThan(VerseScales.lineCount(long)),
    );

    expect(VerseScales.exportShapes(_short), CardShape.values);
    expect(VerseScales.exportShapes(medium), contains(CardShape.feed));
    expect(VerseScales.exportShapes(long), contains(CardShape.feed));
    expect(VerseScales.exportShapes(longest), [CardShape.story]);
    expect(VerseScales.previewShape(longest), CardShape.story);
    expect(VerseScales.previewShape(long), CardShape.portrait);
  });

  test('each style gets smaller and tighter as the verse gets longer', () {
    final samples = [
      _short,
      _until(VerseBucket.medium),
      _until(VerseBucket.long),
      _until(VerseBucket.longest),
    ];
    for (final id in VerseScales.byId.keys) {
      final readings = [for (final text in samples) VerseScales.read(id, text)];
      expect(readings.map((r) => r.bucket).toList(), [
        VerseBucket.short,
        VerseBucket.medium,
        VerseBucket.long,
        VerseBucket.longest,
      ], reason: id);
      for (var i = 0; i < readings.length; i++) {
        final r = readings[i];
        final scale = VerseScales.of(id);
        expect(
          r.size,
          inInclusiveRange(scale.minSize, scale.maxSize),
          reason: id,
        );
        expect(
          r.height,
          inInclusiveRange(scale.tightHeight, scale.looseHeight),
          reason: id,
        );
        expect(
          r.gap,
          inInclusiveRange(scale.tightGap, scale.looseGap),
          reason: id,
        );
        expect(
          r.pad,
          inInclusiveRange(scale.tightPad, scale.loosePad),
          reason: id,
        );
        if (i > 0) {
          expect(r.size, lessThanOrEqualTo(readings[i - 1].size), reason: id);
          expect(
            r.height,
            lessThanOrEqualTo(readings[i - 1].height),
            reason: id,
          );
          expect(r.gap, lessThanOrEqualTo(readings[i - 1].gap), reason: id);
        }
      }
      expect(readings.first.size, scaleOf(id).maxSize, reason: id);
      expect(readings.last.size, VerseScales.of(id).minSize, reason: id);
      expect(
        readings.last.spacing,
        lessThan(readings.first.spacing),
        reason: id,
      );
    }
  });

  test(
    'a style that cannot fit the story frame is hidden, then we fall back',
    () {
      VerseScales.byId['cramped'] = StyleTypeScale(
        maxSize: 40,
        minSize: 28,
        looseHeight: 1.4,
        tightHeight: 1.3,
        looseGap: 20,
        tightGap: 16,
        loosePad: 20,
        tightPad: 16,
        storyWidth: 70,
        storyHeight: 36,
        squareWidth: 70,
        squareHeight: 36,
        styleFor: (size, height) => TextStyle(fontSize: size, height: height),
      );
      final cramped = _style('cramped');
      final vigil = CardCatalog.bundled.first;
      final long = _until(VerseBucket.long);
      expect(VerseScales.of('cramped').fitsStory(long), isFalse);
      expect(VerseScales.of('vigil').fitsStory(long), isTrue);
      expect(VerseScales.of('vigil').fitsStory(_short), isTrue);

      final offered = VerseScales.stylesForVerse([cramped, vigil], long);
      expect(offered.map((s) => s.id), ['vigil']);
      expect(VerseScales.indexOfStyle(offered, 'cramped'), 0);
      expect(VerseScales.indexOfStyle(offered, 'vigil'), 0);

      // Nothing fits: keep the list so the screen is not blank.
      expect(VerseScales.stylesForVerse([cramped], long).single.id, 'cramped');
    },
  );

  test(
    'the longest KJV verse stays on story and every style can still show it',
    () {
      // Esther 8:9 is 528 characters, the longest verse in the KJV. A repeated
      // word of that length is the same measure the buckets use.
      final esther = _ofLength(528);
      expect(VerseScales.bucketOf(esther), VerseBucket.longest);
      expect(VerseScales.exportShapes(esther), [CardShape.story]);
      final hidden = [
        for (final id in VerseScales.byId.keys)
          if (!VerseScales.of(id).fitsStory(esther)) id,
      ];
      expect(hidden, isEmpty, reason: 'styles that cannot hold Esther 8:9');
      for (final id in VerseScales.byId.keys) {
        expect(
          VerseScales.of(id).fitsSquare(esther),
          isFalse,
          reason: '$id would still offer a square for the longest verse',
        );
      }
    },
  );

  test(
    'verses that are not the longest still fit a square at each style minimum',
    () {
      final long = _until(VerseBucket.long);
      expect(VerseScales.bucketOf(long), VerseBucket.long);
      for (final id in VerseScales.byId.keys) {
        expect(VerseScales.of(id).fitsSquare(long), isTrue, reason: id);
      }
    },
  );

  testWidgets('Song of Solomon keeps 1:1 on Highlight and the other styles', (
    tester,
  ) async {
    final example = File('remote_card_styles.example.json').readAsStringSync();
    CardCatalog.apply(CardStyleOverrides.parse(example));
    const reference = 'Song of Solomon 1:1';
    final content = _content(
      reference,
      text:
          'Let him kiss me with the kisses of his mouth: for thy love is '
          'better than wine.',
    );

    for (final style in CardCatalog.styles) {
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
        final why = '${style.id} ${shape.name}';
        expect(tester.takeException(), isNull, reason: why);
        final referenceText = tester
            .widget<Text>(
              find.descendant(
                of: find.byType(VerseReference).first,
                matching: find.byType(Text),
              ),
            )
            .data!;
        expect(
          referenceText.replaceAll('\n', ' '),
          contains('1:1'),
          reason: why,
        );
        expect(
          referenceText.toUpperCase(),
          contains('SONG OF SOLOMON'),
          reason: why,
        );
        expect(referenceText, isNot(contains('…')), reason: why);
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
}

StyleTypeScale scaleOf(String id) => VerseScales.of(id);

CardStyleSpec _style(String id) => CardStyleSpec(
  id: id,
  name: id,
  tags: const {},
  variants: [
    CardVariant(
      id: 'a',
      name: 'A',
      swatch: const Color(0xFF000000),
      palette: const CardPalette(
        background: Color(0xFFFFFFFF),
        ink: Color(0xFF000000),
        accent: Color(0xFF000000),
      ),
    ),
  ],
  builder: (_, _, _) => const SizedBox.shrink(),
);

Iterable<RenderParagraph> _paragraphs(WidgetTester tester) sync* {
  final found = <RenderParagraph>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) found.add(node);
    node.visitChildren(visit);
  }

  visit(tester.renderObject(find.byType(QuoteCard)));
  yield* found;
}

double _textHeight(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
  )..layout(maxWidth: paragraph.size.width);
  final height = painter.height;
  painter.dispose();
  return height;
}
