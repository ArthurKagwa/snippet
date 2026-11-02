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

/// What 1.0.2 offered for these passages, as shape names. The new fit must
/// keep every one of them and may add more.
final _before = <String, Map<String, List<String>>>{
  'kjv EST 8:9': {
    'marquee': ['portrait', 'story'],
    'highlight': ['portrait', 'story'],
    'psalter': ['portrait', 'story'],
    'vigil': ['portrait', 'story'],
    'riso': ['feed', 'portrait', 'story'],
    'dawn': ['portrait', 'story'],
    'swiss': ['feed', 'portrait', 'story'],
    'night-watch': ['portrait', 'story'],
    'cobalt-arch': ['portrait', 'story'],
  },
  'web EST 8:9': {
    'marquee': ['portrait', 'story'],
    'highlight': ['portrait', 'story'],
    'psalter': ['portrait', 'story'],
    'vigil': ['portrait', 'story'],
    'riso': ['feed', 'portrait', 'story'],
    'dawn': ['portrait', 'story'],
    'swiss': ['feed', 'portrait', 'story'],
    'night-watch': ['feed', 'portrait', 'story'],
    'cobalt-arch': ['portrait', 'story'],
  },
  'kjv REV 20:4': {
    for (final id in _styleIds) id: ['feed', 'portrait', 'story'],
  },
  'web REV 20:4': {
    for (final id in _styleIds) id: ['feed', 'portrait', 'story'],
  },
  'kjv PSA 23:1-6': {
    'marquee': ['portrait', 'story'],
    'highlight': ['story'],
    'psalter': ['portrait', 'story'],
    'vigil': ['story'],
    'riso': ['feed', 'portrait', 'story'],
    'dawn': ['portrait', 'story'],
    'swiss': ['portrait', 'story'],
    'night-watch': ['portrait', 'story'],
    'cobalt-arch': ['portrait', 'story'],
  },
  'web PSA 23:1-6': {
    'marquee': ['portrait', 'story'],
    'highlight': ['story'],
    'psalter': ['portrait', 'story'],
    'vigil': ['portrait', 'story'],
    'riso': ['feed', 'portrait', 'story'],
    'dawn': ['portrait', 'story'],
    'swiss': ['portrait', 'story'],
    'night-watch': ['portrait', 'story'],
    'cobalt-arch': ['portrait', 'story'],
  },
  'kjv JOH 3:16-21': {
    'marquee': ['story'],
    'highlight': ['story'],
    'psalter': ['story'],
    'vigil': ['story'],
    'riso': ['portrait', 'story'],
    'dawn': ['story'],
    'swiss': ['story'],
    'night-watch': ['story'],
    'cobalt-arch': ['story'],
  },
  'web JOH 3:16-21': {
    'marquee': ['story'],
    'highlight': ['story'],
    'psalter': ['story'],
    'vigil': ['story'],
    'riso': ['portrait', 'story'],
    'dawn': ['story'],
    'swiss': ['story'],
    'night-watch': ['story'],
    'cobalt-arch': ['story'],
  },
};

const _styleIds = [
  'marquee',
  'highlight',
  'psalter',
  'vigil',
  'riso',
  'dawn',
  'swiss',
  'night-watch',
  'cobalt-arch',
];

const _passages = [
  ('kjv EST 8:9', 'kjv', 'EST', 8, 9, 9),
  ('web EST 8:9', 'web', 'EST', 8, 9, 9),
  ('kjv REV 20:4', 'kjv', 'REV', 20, 4, 4),
  ('web REV 20:4', 'web', 'REV', 20, 4, 4),
  ('kjv PSA 23:1-6', 'kjv', 'PSA', 23, 1, 6),
  ('web PSA 23:1-6', 'web', 'PSA', 23, 1, 6),
  ('kjv JOH 3:16-21', 'kjv', 'JOH', 3, 16, 21),
  ('web JOH 3:16-21', 'web', 'JOH', 3, 16, 21),
];

String _repeat(int words) => List.filled(words, 'beloved').join(' ');

CardContent _content(String reference, {String text = _short}) =>
    CardContent(text: text, reference: reference, translation: 'KJV');

void main() {
  tearDown(() {
    CardCatalog.apply(CardStyleOverrides.none);
    VerseScales.byId.remove('cramped');
    VerseScales.resetLayoutLimits();
  });

  test('the length curve grows smoothly and still scales the type', () {
    expect(VerseScales.lengthTightness(_short), 0);
    expect(VerseScales.lengthTightness(''), 0);
    expect(VerseScales.lineCount(''), 1);

    final steps = [
      for (var lines = 1; lines <= 18; lines++)
        VerseScales.lengthTightness(_textOfLineCount(lines)),
    ];
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], greaterThanOrEqualTo(steps[i - 1]));
      expect(steps[i] - steps[i - 1], lessThanOrEqualTo(0.35));
    }
    expect(steps.first, 0);
    expect(steps.last, 1);

    final vigil = CardCatalog.bundled.first;
    expect(
      VerseScales.exportShapes(vigil, _content('John 11:35', text: _short)),
      CardShape.values,
    );
    expect(
      VerseScales.previewShape(vigil, _content('John 11:35', text: _short)),
      CardShape.portrait,
    );

    final longest = _textOfLineCount(16);
    final reading = VerseScales.read('vigil', longest);
    expect(reading.tightness, 1);
    expect(reading.size, VerseScales.of('vigil').minSize);
    expect(reading.height, VerseScales.of('vigil').tightHeight);
  });

  test('each style gets smaller and tighter as the verse gets longer', () {
    final samples = [
      _textOfLineCount(1),
      _textOfLineCount(5),
      _textOfLineCount(8),
      _textOfLineCount(12),
      _textOfLineCount(16),
    ];
    for (final id in VerseScales.byId.keys) {
      final readings = [for (final text in samples) VerseScales.read(id, text)];
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
          inInclusiveRange(
            mathMin(scale.tightHeight, scale.looseHeight),
            mathMax(scale.tightHeight, scale.looseHeight),
          ),
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
          expect(r.tightness, greaterThanOrEqualTo(readings[i - 1].tightness));
          expect(r.size, lessThanOrEqualTo(readings[i - 1].size), reason: id);
          expect(
            r.height,
            lessThanOrEqualTo(readings[i - 1].height),
            reason: id,
          );
          expect(r.gap, lessThanOrEqualTo(readings[i - 1].gap), reason: id);
          expect(r.pad, lessThanOrEqualTo(readings[i - 1].pad), reason: id);
        }
      }
      expect(readings.first.size, scaleOf(id).maxSize, reason: id);
      expect(readings.first.tightness, 0, reason: id);
      expect(readings.last.size, VerseScales.of(id).minSize, reason: id);
      expect(readings.last.tightness, 1, reason: id);
      expect(
        readings.last.spacing,
        lessThan(readings.first.spacing),
        reason: id,
      );
    }
  });

  test('floors stay legible and short verses keep the loose end', () {
    const body = [
      'vigil',
      'dawn',
      'night-watch',
      'cobalt-arch',
      'psalter',
      'highlight',
    ];
    for (final id in body) {
      final scale = VerseScales.of(id);
      expect(scale.minSize, inInclusiveRange(11, 12), reason: id);
      expect(scale.tightHeight, greaterThanOrEqualTo(1.15), reason: id);
      expect(
        scale.tightHeight,
        lessThanOrEqualTo(scale.looseHeight),
        reason: id,
      );
      expect(scale.maxSize, greaterThan(scale.minSize), reason: id);
    }
    final swiss = VerseScales.of('swiss');
    expect(swiss.minSize, inInclusiveRange(11, 12));
    expect(swiss.tightHeight, greaterThanOrEqualTo(1));
    expect(swiss.tightHeight, lessThanOrEqualTo(swiss.looseHeight));
    for (final id in ['marquee', 'riso']) {
      final scale = VerseScales.of(id);
      expect(scale.minSize, inInclusiveRange(11, 12), reason: id);
      expect(scale.tightHeight, lessThan(1.15), reason: id);
      expect(
        scale.tightHeight,
        lessThanOrEqualTo(scale.looseHeight),
        reason: id,
      );
      expect(scale.maxSize, greaterThan(30), reason: id);
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
      final long = _repeat(12);
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

  test('remote minFontSize and minLineHeight lower that style floor', () {
    CardCatalog.apply(
      CardStyleOverrides.parse(
        '{"styles":{"highlight":{"layout":{"type":"text","fit":true,'
        '"minFontSize":11.5,"minLineHeight":1.16}}}}',
      ),
    );
    final scale = VerseScales.of('highlight');
    expect(scale.minSize, 11.5);
    expect(scale.tightHeight, 1.16);
    expect(scale.maxSize, 24);
    expect(scale.looseHeight, 1.95);
  });

  test('long passages keep every size 1.0.2 offered, and add more', () {
    _applyExample();
    final after = <String, Map<String, List<String>>>{};
    var beforeCount = 0;
    var afterCount = 0;
    final lines = <String>[];
    for (final passage in _passages) {
      final (label, translation, book, chapter, start, end) = passage;
      final content = _passage(translation, book, chapter, start, end);
      final row = <String, List<String>>{};
      final cells = <String>[];
      for (final style in CardCatalog.styles) {
        final names = [
          for (final shape in VerseScales.exportShapes(style, content))
            shape.name,
        ];
        row[style.id] = names;
        final previous = _before[label]![style.id]!;
        expect(
          names,
          containsAll(previous),
          reason: '$label ${style.id} lost a size',
        );
        expect(
          names,
          ['feed', 'portrait', 'story'],
          reason: '$label ${style.id}',
        );
        beforeCount += previous.length;
        afterCount += names.length;
        cells.add(_marks(names));
      }
      after[label] = row;
      lines.add('${label.padRight(16)} ${cells.join('  ')}');
    }
    expect(beforeCount, 150);
    expect(afterCount, 216);
    // ignore: avoid_print
    print(
      'style-size coverage before $beforeCount after $afterCount\n'
      '${''.padRight(16)} ${_styleIds.map((id) => id.padRight(5)).join('  ')}\n'
      '${lines.join('\n')}',
    );
    // Esther 8:9 KJV had lost the square on every style but Riso and Swiss.
    final esther = after['kjv EST 8:9']!;
    for (final id in [
      'highlight',
      'marquee',
      'psalter',
      'vigil',
      'dawn',
      'night-watch',
      'cobalt-arch',
    ]) {
      expect(esther[id], contains('feed'), reason: id);
    }
  });

  testWidgets('a short verse is painted at the style maximum', (tester) async {
    _applyExample();
    final content = _content('John 11:35');
    for (final style in CardCatalog.styles) {
      final scale = VerseScales.of(style.id);
      for (final shape in CardShape.values) {
        final reading = VerseScales.forShape(style, content, shape);
        expect(reading.tightness, 0, reason: '${style.id} ${shape.name}');
        expect(
          reading.size,
          scale.maxSize,
          reason: '${style.id} ${shape.name}',
        );
        expect(
          reading.height,
          scale.looseHeight,
          reason: '${style.id} ${shape.name}',
        );
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
        final painted = _verseParagraph(tester, content.text);
        expect(
          painted.text.style?.fontSize,
          closeTo(scale.maxSize, 0.05),
          reason: '${style.id} ${shape.name}',
        );
        expect(
          painted.text.style?.height,
          closeTo(scale.looseHeight, 0.001),
          reason: '${style.id} ${shape.name}',
        );
      }
    }
  });

  testWidgets(
    'Hebrews 12:1-2 WEB keeps a square on the styles Arthur checked',
    (tester) async {
      _applyExample();
      final content = _passage('web', 'HEB', 12, 1, 2);
      expect(VerseScales.lineCount(content.text), greaterThanOrEqualTo(11));
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

double mathMin(double a, double b) => a < b ? a : b;

double mathMax(double a, double b) => a > b ? a : b;

StyleTypeScale scaleOf(String id) => VerseScales.of(id);

String _marks(List<String> names) {
  final marks = [
    if (names.contains('feed')) 'F',
    if (names.contains('portrait')) 'P',
    if (names.contains('story')) 'S',
  ].join();
  return marks.padRight(5);
}

/// Repeats a word until the shared line measure reports [lines] lines.
String _textOfLineCount(int lines) {
  for (var words = 1; words < 4000; words++) {
    final text = _repeat(words);
    if (VerseScales.lineCount(text) >= lines) return text;
  }
  fail('no verse reached $lines lines');
}

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

/// Verse height at the fitted font, over the well the card actually gives it.
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
  final found = _verseParagraph(tester, content.text);
  final reading = VerseScales.forShape(style, content, shape);
  final painted = found.text.style;
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

RenderParagraph _verseParagraph(WidgetTester tester, String text) {
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
  final found = verse;
  expect(found, isNotNull);
  return found!;
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
