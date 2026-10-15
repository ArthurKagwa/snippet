import 'package:flutter/painting.dart';

import '../../core/theme/snippet_fonts.dart';
import '../card_palette.dart';
import '../card_style_overrides.dart';

/// A colour in a remote layout: a palette slot (`ink`, `accent`, ...) or
/// `#RRGGBB`, either optionally with `@opacity`, e.g. `border@0.12`.
class ColorRef {
  const ColorRef._(this._slot, this._fixed, this._opacity);

  final String? _slot;
  final Color? _fixed;
  final double _opacity;

  static const _slots = {
    'background',
    'backgroundEnd',
    'ink',
    'accent',
    'accentDim',
    'surface',
    'surfaceInk',
    'border',
  };

  static ColorRef? parse(Object? value) {
    if (value is! String) return null;
    final parts = value.trim().split('@');
    if (parts.length > 2) return null;
    final opacity = parts.length == 2 ? double.tryParse(parts[1]) : 1.0;
    if (opacity == null || opacity < 0 || opacity > 1) return null;
    final name = parts[0];
    if (_slots.contains(name)) return ColorRef._(name, null, opacity);
    final fixed = parseHexColor(name);
    return fixed == null ? null : ColorRef._(null, fixed, opacity);
  }

  Color resolve(CardPalette p) {
    final base =
        _fixed ??
        switch (_slot) {
          'background' => p.background,
          'backgroundEnd' => p.backgroundEnd ?? p.background,
          'accent' => p.accent,
          'accentDim' => p.accentDim,
          'surface' => p.surface,
          'surfaceInk' => p.surfaceInk,
          'border' => p.border,
          _ => p.ink,
        };
    return _opacity == 1 ? base : base.withValues(alpha: base.a * _opacity);
  }
}

double? numberOf(Object? v) => v is num ? v.toDouble() : null;

/// A number for all sides, or `{"all", "horizontal", "vertical", "left",
/// "top", "right", "bottom"}` with the specific sides winning.
EdgeInsets insetsOf(Object? v) {
  if (v is num) return EdgeInsets.all(v.toDouble());
  if (v is! Map) return EdgeInsets.zero;
  final all = numberOf(v['all']) ?? 0;
  final h = numberOf(v['horizontal']) ?? all;
  final vert = numberOf(v['vertical']) ?? all;
  return EdgeInsets.fromLTRB(
    numberOf(v['left']) ?? h,
    numberOf(v['top']) ?? vert,
    numberOf(v['right']) ?? h,
    numberOf(v['bottom']) ?? vert,
  );
}

/// A number for all corners, or `{"top", "bottom", "topLeft", ...}`. Radii
/// larger than the box shrink to fit, so `{"top": 999}` makes an arch.
BorderRadius? radiusOf(Object? v) {
  if (v is num) return BorderRadius.circular(v.toDouble());
  if (v is! Map) return null;
  Radius r(String corner, String side) =>
      Radius.circular(numberOf(v[corner]) ?? numberOf(v[side]) ?? 0);
  return BorderRadius.only(
    topLeft: r('topLeft', 'top'),
    topRight: r('topRight', 'top'),
    bottomLeft: r('bottomLeft', 'bottom'),
    bottomRight: r('bottomRight', 'bottom'),
  );
}

/// `center`, `topLeft`, `bottomRight`, ... or `[x, y]` from -1 to 1.
Alignment? alignmentOf(Object? v) {
  if (v is List && v.length == 2 && v.every((e) => e is num)) {
    return Alignment((v[0] as num).toDouble(), (v[1] as num).toDouble());
  }
  return switch (v) {
    'topLeft' => Alignment.topLeft,
    'topCenter' || 'top' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' || 'left' => Alignment.centerLeft,
    'center' => Alignment.center,
    'centerRight' || 'right' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' || 'bottom' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => null,
  };
}

TextAlign textAlignOf(Object? v) => switch (v) {
  'center' => TextAlign.center,
  'right' || 'end' => TextAlign.end,
  'justify' => TextAlign.justify,
  _ => TextAlign.start,
};

/// A bundled font: `syne`, `serif`, `sans`, `cormorant`, `mono` or
/// `grotesk`, with `weight` (100-900), `italic` and (grotesk) `condensed`.
class FontRef {
  const FontRef({
    this.family = 'serif',
    this.weight = 400,
    this.italic = false,
    this.condensed = false,
  });

  factory FontRef.fromJson(Map json) => FontRef(
    family: json['font'] is String ? json['font'] as String : 'serif',
    weight: (numberOf(json['weight']) ?? 400).clamp(100, 900).round(),
    italic: json['italic'] == true,
    condensed: json['condensed'] == true,
  );

  final String family;
  final int weight;
  final bool italic;
  final bool condensed;

  TextStyle style(
    double size, {
    Color? color,
    double? height,
    double? tracking,
  }) {
    final fontWeight = FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)];
    final wght = FontVariation('wght', fontWeight.value.toDouble());
    final (name, variations) = switch (family) {
      'syne' => (SnippetFonts.syne, [wght]),
      'sans' => (SnippetFonts.sans, [wght]),
      'cormorant' => (SnippetFonts.cormorant, [wght]),
      'mono' => (SnippetFonts.mono, <FontVariation>[]),
      'grotesk' => (
        SnippetFonts.bricolage,
        [
          wght,
          FontVariation('wdth', condensed ? 75 : 100),
          const FontVariation('opsz', 96),
        ],
      ),
      _ => (SnippetFonts.serif, <FontVariation>[]),
    };
    return TextStyle(
      fontFamily: name,
      fontSize: size,
      fontWeight: fontWeight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontVariations: variations,
      color: color,
      height: height,
      letterSpacing: tracking == null ? null : size * tracking,
      decoration: TextDecoration.none,
    );
  }
}
