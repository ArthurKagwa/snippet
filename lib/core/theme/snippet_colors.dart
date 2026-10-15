import 'package:flutter/material.dart';

/// App chrome color tokens (Cobalt swipe design). Card art has its own
/// palettes in `cards/card_palettes.dart`.
@immutable
class SnippetColors extends ThemeExtension<SnippetColors> {
  const SnippetColors({
    required this.cobalt,
    required this.cobaltDeep,
    required this.black,
    required this.white,
    required this.line,
    required this.lineDark,
    required this.mist,
    required this.mistFaint,
    required this.lime,
    required this.stone,
    required this.stone2,
    required this.ink,
    required this.inkDim,
    required this.surfaceDark,
    required this.archLine,
    required this.track,
    required this.scrim,
    required this.shadow,
    required this.danger,
    required this.googleBlue,
    required this.googleGreen,
    required this.googleYellow,
    required this.googleRed,
  });

  static const SnippetColors cobaltSwipe = SnippetColors(
    cobalt: Color(0xFF2433D6),
    cobaltDeep: Color(0xFF121A7E),
    black: Color(0xFF0B0B0D),
    white: Color(0xFFF7F7FF),
    line: Color(0x47F7F7FF),
    lineDark: Color(0xFF26262B),
    mist: Color(0xFFC3C9FF),
    mistFaint: Color(0xFF8A90B8),
    lime: Color(0xFFD9F75B),
    stone: Color(0xFFF1EEE8),
    stone2: Color(0xFFE4E0D8),
    ink: Color(0xFF10133F),
    inkDim: Color(0xFF4A4E7A),
    surfaceDark: Color(0xFF1A1A1F),
    archLine: Color(0xFF3A3D5C),
    track: Color(0x4DF7F7FF),
    scrim: Color(0x8C000000),
    shadow: Color(0x80000000),
    danger: Color(0xFFFF8A80),
    googleBlue: Color(0xFF4285F4),
    googleGreen: Color(0xFF34A853),
    googleYellow: Color(0xFFFBBC05),
    googleRed: Color(0xFFEA4335),
  );

  final Color cobalt;
  final Color cobaltDeep;
  final Color black;
  final Color white;
  final Color line;
  final Color lineDark;
  final Color mist;
  final Color mistFaint;
  final Color lime;
  final Color stone;
  final Color stone2;
  final Color ink;
  final Color inkDim;
  final Color surfaceDark;
  final Color archLine;
  final Color track;
  final Color scrim;
  final Color shadow;
  final Color danger;
  final Color googleBlue;
  final Color googleGreen;
  final Color googleYellow;
  final Color googleRed;

  @override
  SnippetColors copyWith() => this;

  @override
  SnippetColors lerp(SnippetColors? other, double t) => this;
}

extension SnippetColorsX on BuildContext {
  SnippetColors get colors =>
      Theme.of(this).extension<SnippetColors>() ?? SnippetColors.cobaltSwipe;
}
