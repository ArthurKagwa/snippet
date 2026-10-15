import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colors one card variant needs. Each style reads the slots it uses.
@immutable
class CardPalette {
  const CardPalette({
    required this.background,
    this.backgroundEnd,
    required this.ink,
    required this.accent,
    Color? accentDim,
    Color? surface,
    Color? surfaceInk,
    Color? border,
  }) : accentDim = accentDim ?? accent,
       surface = surface ?? background,
       surfaceInk = surfaceInk ?? ink,
       border = border ?? ink;

  /// Solid fill, or gradient start when [backgroundEnd] is set.
  final Color background;
  final Color? backgroundEnd;

  /// Main verse text.
  final Color ink;

  /// Ornaments, reference line, rules.
  final Color accent;

  /// Quieter accent (frame lines).
  final Color accentDim;

  /// Secondary plate (Riso tag, Cobalt Arch arch).
  final Color surface;
  final Color surfaceInk;

  /// Outline (Riso Loud).
  final Color border;
}

/// A named colourway of a style.
@immutable
class CardVariant {
  const CardVariant({
    required this.id,
    required this.name,
    required this.swatch,
    required this.palette,
  });

  final String id;
  final String name;
  final Color swatch;
  final CardPalette palette;
}
