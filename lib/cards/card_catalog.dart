import 'card_style_overrides.dart';
import 'card_style_spec.dart';
import 'verse_scale.dart';
import 'palettes/graphic_palettes.dart';
import 'palettes/serif_palettes.dart';
import 'styles/cobalt_arch_card.dart';
import 'styles/dawn_card.dart';
import 'styles/night_watch_card.dart';
import 'styles/riso_card.dart';
import 'styles/swiss_card.dart';
import 'styles/vigil_card.dart';

/// The card styles, as bundled and then adjusted by [apply].
abstract final class CardCatalog {
  /// Offered styles, in swipe order.
  static List<CardStyleSpec> get styles => _shown;

  static List<CardStyleSpec> _shown = bundled;
  static List<CardStyleSpec> _all = bundled;

  /// Swaps in [overrides] over the bundled styles. Screens opened after
  /// this see the change; [CardStyleOverrides.none] restores the bundle.
  static void apply(CardStyleOverrides overrides) {
    final all = overrides.applyTo(bundled);
    _all = all;
    _shown = [
      for (final s in all)
        if (!overrides.isHidden(s.id, all)) s,
    ];
  }

  static final List<CardStyleSpec> bundled = [
    CardStyleSpec(
      id: 'vigil',
      name: 'Vigil',
      tags: {StyleTag.classic},
      variants: SerifPalettes.vigil,
      builder: (c, p, s) => VigilCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('vigil', c.text),
      ),
    ),
    CardStyleSpec(
      id: 'riso',
      name: 'Riso Loud',
      tags: {StyleTag.bold},
      variants: GraphicPalettes.riso,
      builder: (c, p, s) => RisoCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('riso', c.text),
      ),
    ),
    CardStyleSpec(
      id: 'dawn',
      name: 'Dawn',
      tags: {StyleTag.soft},
      variants: SerifPalettes.dawn,
      builder: (c, p, s) => DawnCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('dawn', c.text),
      ),
    ),
    CardStyleSpec(
      id: 'swiss',
      name: 'Swiss',
      tags: {StyleTag.bold, StyleTag.minimal},
      variants: GraphicPalettes.swiss,
      builder: (c, p, s) => SwissCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('swiss', c.text),
      ),
    ),
    CardStyleSpec(
      id: 'night-watch',
      name: 'Night Watch',
      tags: {StyleTag.classic, StyleTag.minimal},
      variants: SerifPalettes.nightWatch,
      builder: (c, p, s) => NightWatchCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('night-watch', c.text),
      ),
    ),
    CardStyleSpec(
      id: 'cobalt-arch',
      name: 'Cobalt Arch',
      tags: {StyleTag.soft, StyleTag.minimal},
      variants: GraphicPalettes.cobaltArch,
      builder: (c, p, s) => CobaltArchCard(
        content: c,
        palette: p,
        shape: s,
        reading: VerseScales.read('cobalt-arch', c.text),
      ),
    ),
  ];

  static int indexOf(String? styleId) {
    final i = styles.indexWhere((s) => s.id == styleId);
    return i < 0 ? 0 : i;
  }

  /// Also finds hidden styles, so saved cards keep their look.
  static CardStyleSpec byId(String? styleId) =>
      _all.where((s) => s.id == styleId).firstOrNull ??
      styles[indexOf(styleId)];
}
