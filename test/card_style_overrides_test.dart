import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_catalog.dart';
import 'package:snippet/cards/card_style_overrides.dart';
import 'package:snippet/cards/card_style_spec.dart';
import 'package:snippet/services/firebase_content_config_service.dart';

void main() {
  tearDown(() => CardCatalog.apply(CardStyleOverrides.none));

  List<String> ids() => [for (final s in CardCatalog.styles) s.id];
  final bundledIds = [for (final s in CardCatalog.bundled) s.id];

  test('parseHexColor reads 6 and 8 digit hex', () {
    expect(parseHexColor('#FF7A1A'), const Color(0xFFFF7A1A));
    expect(parseHexColor('80ff7a1a'), const Color(0x80FF7A1A));
    for (final bad in [null, 7, '', '#FFF', '#GG0000', 'red']) {
      expect(parseHexColor(bad), isNull, reason: '$bad');
    }
  });

  test('empty or bad JSON leaves the bundled styles', () {
    for (final json in ['', '{}', 'not json', '[]', '{"order": 3}']) {
      CardCatalog.apply(CardStyleOverrides.parse(json));
      expect(ids(), bundledIds, reason: json);
    }
  });

  test('reorders and hides styles, keeping hidden ones for saved cards', () {
    CardCatalog.apply(
      CardStyleOverrides.parse(
        '{"order": ["dawn", "nope", "swiss"], "hidden": ["vigil"]}',
      ),
    );
    expect(ids(), ['dawn', 'swiss', 'riso', 'night-watch', 'cobalt-arch']);
    expect(CardCatalog.byId('vigil').id, 'vigil');
    expect(CardCatalog.indexOf('vigil'), 0);
  });

  test('never hides every style', () {
    CardCatalog.apply(
      CardStyleOverrides(hidden: {for (final id in bundledIds) id}),
    );
    expect(ids(), bundledIds);
  });

  test('renames, retags, recolours, adds and hides colourways', () {
    CardCatalog.apply(
      CardStyleOverrides.parse('''{
        "styles": {
          "riso": {
            "name": "Riso",
            "tags": ["soft", "unknown"],
            "hidden_variants": ["yellow"],
            "variants": [
              {"id": "pink", "ink": "#FFFFFF"},
              {"id": "tangerine", "name": "Tangerine",
               "background": "#FF7A1A", "ink": "#141414"},
              {"id": "broken", "background": "#000000"}
            ]
          }
        }
      }'''),
    );
    final bundled = CardCatalog.bundled.firstWhere((s) => s.id == 'riso');
    final riso = CardCatalog.byId('riso');
    expect(riso.name, 'Riso');
    expect(riso.tags, {StyleTag.soft});

    final pink = riso.variant('pink');
    final bundledPink = bundled.variant('pink');
    expect(pink.palette.ink, const Color(0xFFFFFFFF));
    expect(pink.palette.background, bundledPink.palette.background);
    expect(pink.palette.surface, bundledPink.palette.surface);
    expect(pink.name, bundledPink.name);

    final ids = [for (final v in riso.variants) v.id];
    expect(ids, isNot(contains('yellow')));
    expect(ids, isNot(contains('broken')));
    expect(ids.last, 'tangerine');

    final tangerine = riso.variant('tangerine');
    expect(tangerine.swatch, const Color(0xFFFF7A1A));
    expect(tangerine.palette.accent, const Color(0xFF141414));

    // A hidden colourway still renders on a saved card.
    expect(riso.variant('yellow').id, 'yellow');
  });

  test('parseRemoteContent carries card_styles', () {
    final c = parseRemoteContent(
      verseCalendarJson: '{}',
      announcement: '',
      cardStylesJson: '{"hidden": ["swiss"]}',
    );
    expect(c.cardStyles.hidden, {'swiss'});
  });
}
