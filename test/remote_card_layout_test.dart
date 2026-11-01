import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/cards/card_palette.dart';
import 'package:snippet/cards/card_shape.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/marked_text.dart';
import 'package:snippet/cards/quote_card.dart';
import 'package:snippet/cards/remote/layout_values.dart';

const _content = CardContent(
  text:
      'Be still, and know that I am God: I will be exalted among the '
      'heathen, I will be exalted in the earth.',
  reference: 'Psalm 46:10',
  translation: 'KJV',
);

String _withStyle(String layout, {String variants = _variants}) =>
    '{"styles": {"new": {"name": "New", "layout": $layout, '
    '"variants": $variants}}}';

const _variants = '[{"id": "a", "background": "#000000", "ink": "#FFFFFF"}]';

void main() {
  tearDown(() => CardCatalog.apply(CardStyleOverrides.none));

  final example = File('remote_card_styles.example.json').readAsStringSync();

  test('the example adds Marquee, Highlight and Psalter in front', () {
    CardCatalog.apply(CardStyleOverrides.parse(example));
    final styles = CardCatalog.styles;
    expect(styles.length, CardCatalog.bundled.length + 3);
    expect(styles[0].name, 'Marquee');
    expect(styles[0].tags.map((t) => t.name), ['bold']);
    expect(styles[1].name, 'Highlight');
    expect(styles[2].name, 'Psalter');
    expect(
      [for (final v in styles[2].variants) v.id],
      ['night', 'vellum', 'lapis'],
    );
  });

  testWidgets('example styles draw in every shape and colourway', (
    tester,
  ) async {
    CardCatalog.apply(CardStyleOverrides.parse(example));
    for (final id in ['psalter', 'marquee', 'highlight']) {
      final style = CardCatalog.byId(id);
      for (final variant in style.variants) {
        for (final shape in CardShape.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: 320,
                  child: QuoteCard(
                    content: _content,
                    style: style,
                    variant: variant,
                    shape: shape,
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$id ${variant.id} ${shape.name}',
          );
          expect(
            find.textContaining(RegExp('be still', caseSensitive: false)),
            findsOneWidget,
          );
        }
      }
    }
  });

  test('a style with an unknown node or no usable colourway is dropped', () {
    for (final json in [
      _withStyle('{"type": "sparkles"}'),
      _withStyle(
        '{"type": "column", "children": [{"type": "text"}, {"type": "x"}]}',
      ),
      _withStyle('{"type": "text"}', variants: '[{"id": "a"}]'),
      _withStyle('{"type": "text"}', variants: '[]'),
    ]) {
      CardCatalog.apply(CardStyleOverrides.parse(json));
      expect(CardCatalog.styles.length, CardCatalog.bundled.length);
    }
  });

  test('a layout on a bundled style redraws it', () {
    final bundled = CardCatalog.byId('swiss');
    CardCatalog.apply(
      CardStyleOverrides.parse(
        '{"styles": {"swiss": {"layout": {"type": "text"}}}}',
      ),
    );
    final swiss = CardCatalog.byId('swiss');
    expect(swiss.builder, isNot(same(bundled.builder)));
    expect(swiss.variants, bundled.variants);
  });

  testWidgets('a text highlight draws a marker band per line', (tester) async {
    Future<void> pump(String text) async {
      CardCatalog.apply(
        CardStyleOverrides.parse(
          _withStyle('{"type": "text", "size": 14, "height": 1.8, $text}'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: QuoteCard(
            content: _content,
            style: CardCatalog.byId('new'),
            variant: CardCatalog.byId('new').variants.single,
          ),
        ),
      );
    }

    await pump('"highlight": "accent@0.4", "highlightPadding": 3');
    expect(tester.takeException(), isNull);
    expect(find.byType(MarkedText), findsOneWidget);

    await pump('"fit": true, "highlight": "#FADCE0"');
    expect(tester.takeException(), isNull);
    expect(find.byType(MarkedText), findsOneWidget);

    await pump('"highlight": "nope"');
    expect(find.byType(MarkedText), findsNothing);
  });

  test('colour refs read palette slots, hex and opacity', () {
    const palette = CardPalette(
      background: Color(0xFF000000),
      ink: Color(0xFFFFFFFF),
      accent: Color(0xFFFF0000),
    );
    expect(ColorRef.parse('accent')!.resolve(palette), palette.accent);
    expect(ColorRef.parse('surface')!.resolve(palette), palette.background);
    expect(
      ColorRef.parse('#00FF00@0.5')!.resolve(palette),
      const Color(0xFF00FF00).withValues(alpha: 0.5),
    );
    for (final bad in ['nope', 'ink@2', 'ink@x', '#12', 3]) {
      expect(ColorRef.parse(bad), isNull, reason: '$bad');
    }
  });
}
