import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/cards/card_measure.dart';
import 'package:snippet/cards/card_palette.dart';
import 'package:snippet/cards/card_shape.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/card_style_spec.dart';
import 'package:snippet/cards/quote_card.dart';
import 'package:snippet/cards/verse_reference.dart';
import 'package:snippet/cards/verse_scale.dart';
import 'package:snippet/data/bible_models.dart';
import 'package:snippet/data/bible_repository.dart';

const _short = 'Jesus wept.';

/// A verse long enough to leave the short bucket without being a paragraph.
String _repeat(int words) => List.filled(words, 'beloved').join(' ');

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

  test('length buckets grow with the verse and still scale the type', () {
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

    final vigil = CardCatalog.bundled.first;
    expect(
      VerseScales.exportShapes(vigil, _content('Psalm 1:1', text: _short)),
      CardShape.values,
    );
    expect(
      VerseScales.previewShape(vigil, _content('Psalm 1:1', text: _short)),
      CardShape.portrait,
    );
    // The bucket still picks the type size. It does not by itself drop a
    // shape; a long verse keeps the square when that style's well holds it.
    expect(VerseScales.read('vigil', longest).bucket, VerseBucket.longest);
    expect(
      VerseScales.read('vigil', longest).size,
      VerseScales.of('vigil').minSize,
    );
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

      final offered = VerseScales.stylesForVerse([
        cramped,
        vigil,
      ], _content('Psalm 1:1', text: long));
      expect(offered.map((s) => s.id), ['vigil']);
      expect(VerseScales.indexOfStyle(offered, 'cramped'), 0);
      expect(VerseScales.indexOfStyle(offered, 'vigil'), 0);

      // Nothing fits: keep the list so the screen is not blank.
      expect(
        VerseScales.stylesForVerse([
          cramped,
        ], _content('Psalm 1:1', text: long)).single.id,
        'cramped',
      );
    },
  );

  testWidgets(
    'Hebrews 12:1-2 WEB keeps a square on the styles Arthur checked',
    (tester) async {
      _applyExample();
      final content = _passage('web', 'HEB', 12, 1, 2);
      expect(VerseScales.bucketOf(content.text), VerseBucket.longest);
      const checked = ['highlight', 'marquee', 'psalter', 'vigil', 'riso'];
      for (final id in checked) {
        final style = CardCatalog.byId(id);
        expect(
          VerseScales.exportShapes(style, content),
          contains(CardShape.feed),
          reason: id,
        );
        final full = await _fullness(tester, style, content, CardShape.feed);
        expect(
          full.height,
          lessThanOrEqualTo(full.slot * (1 + CardMeasure.slack) + 0.5),
          reason: id,
        );
      }
    },
  );

  testWidgets(
    'Esther 8:9 drops the square only where the verse overflows the well',
    (tester) async {
      _applyExample();
      final content = _passage('kjv', 'EST', 8, 9, 9);
      expect(VerseScales.bucketOf(content.text), VerseBucket.longest);
      final square = <String>[];
      final storyOnly = <String>[];
      for (final style in CardCatalog.styles) {
        final shapes = VerseScales.exportShapes(style, content);
        expect(shapes, contains(CardShape.story), reason: style.id);
        final full = await _fullness(tester, style, content, CardShape.feed);
        final fits = full.height <= full.slot * (1 + CardMeasure.slack) + 0.5;
        expect(
          shapes.contains(CardShape.feed),
          fits,
          reason: '${style.id} square is ${full.height} in ${full.slot}',
        );
        if (fits) {
          square.add(style.id);
        } else {
          storyOnly.add(style.id);
        }
        final story = await _fullness(tester, style, content, CardShape.story);
        expect(
          story.height,
          lessThanOrEqualTo(story.slot * (1 + CardMeasure.slack) + 0.5),
          reason: '${style.id} story',
        );
      }
      expect(square, containsAll(['riso', 'swiss']));
      expect(
        storyOnly,
        containsAll([
          'highlight',
          'marquee',
          'psalter',
          'vigil',
          'dawn',
          'night-watch',
          'cobalt-arch',
        ]),
      );
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

void _applyExample() {
  final example = File('remote_card_styles.example.json').readAsStringSync();
  CardCatalog.apply(CardStyleOverrides.parse(example));
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

class _Fill {
  const _Fill(this.height, this.slot);
  final double height;
  final double slot;
}

/// Verse height at the scaled font, over the well the card actually gives it.
Future<_Fill> _fullness(
  WidgetTester tester,
  CardStyleSpec style,
  CardContent content,
  CardShape shape,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: CardShape.designWidth,
          height: shape.designHeight,
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
  final wanted = content.text.trim();
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
  final found = verse;
  expect(found, isNotNull, reason: style.id);
  final reading = VerseScales.read(style.id, content.text);
  final painted = found!.text.style;
  final rendered = painted?.fontSize ?? reading.size;
  final factor = rendered == 0 ? 1.0 : reading.size / rendered;
  final font = (painted ?? const TextStyle()).copyWith(
    fontSize: reading.size,
    height: reading.height,
    letterSpacing: painted?.letterSpacing == null
        ? null
        : painted!.letterSpacing! * factor,
  );
  final painter = TextPainter(
    text: TextSpan(text: found.text.toPlainText(), style: font),
    textAlign: found.textAlign,
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout(maxWidth: found.constraints.maxWidth);
  final height = painter.height;
  painter.dispose();
  return _Fill(height, found.constraints.maxHeight);
}

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
