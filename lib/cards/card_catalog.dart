import 'card_style_spec.dart';
import 'palettes/graphic_palettes.dart';
import 'palettes/serif_palettes.dart';
import 'styles/cobalt_arch_card.dart';
import 'styles/dawn_card.dart';
import 'styles/night_watch_card.dart';
import 'styles/riso_card.dart';
import 'styles/swiss_card.dart';
import 'styles/vigil_card.dart';

/// Every style, in swipe order.
abstract final class CardCatalog {
  static final List<CardStyleSpec> styles = [
    CardStyleSpec(
      id: 'vigil',
      name: 'Vigil',
      tags: {StyleTag.classic},
      variants: SerifPalettes.vigil,
      builder: (c, p, s) => VigilCard(content: c, palette: p, shape: s),
    ),
    CardStyleSpec(
      id: 'riso',
      name: 'Riso Loud',
      tags: {StyleTag.bold},
      variants: GraphicPalettes.riso,
      builder: (c, p, s) => RisoCard(content: c, palette: p, shape: s),
    ),
    CardStyleSpec(
      id: 'dawn',
      name: 'Dawn',
      tags: {StyleTag.soft},
      variants: SerifPalettes.dawn,
      builder: (c, p, s) => DawnCard(content: c, palette: p, shape: s),
    ),
    CardStyleSpec(
      id: 'swiss',
      name: 'Swiss',
      tags: {StyleTag.bold, StyleTag.minimal},
      variants: GraphicPalettes.swiss,
      builder: (c, p, s) => SwissCard(content: c, palette: p, shape: s),
    ),
    CardStyleSpec(
      id: 'night-watch',
      name: 'Night Watch',
      tags: {StyleTag.classic, StyleTag.minimal},
      variants: SerifPalettes.nightWatch,
      builder: (c, p, s) => NightWatchCard(content: c, palette: p, shape: s),
    ),
    CardStyleSpec(
      id: 'cobalt-arch',
      name: 'Cobalt Arch',
      tags: {StyleTag.soft, StyleTag.minimal},
      variants: GraphicPalettes.cobaltArch,
      builder: (c, p, s) => CobaltArchCard(content: c, palette: p, shape: s),
    ),
  ];

  static int indexOf(String? styleId) {
    final i = styles.indexWhere((s) => s.id == styleId);
    return i < 0 ? 0 : i;
  }

  static CardStyleSpec byId(String? styleId) => styles[indexOf(styleId)];
}
