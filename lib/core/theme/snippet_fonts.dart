import 'package:flutter/painting.dart';

/// Bundled font families (see pubspec `fonts:`; OFL licenses in
/// assets/fonts). Variable fonts get their axes set explicitly so weights
/// render true instead of synthesized.
abstract final class SnippetFonts {
  static const String syne = 'Syne';
  static const String serif = 'InstrumentSerif';
  static const String sans = 'InstrumentSans';
  static const String cormorant = 'CormorantGaramond';
  static const String mono = 'SpaceMono';
  static const String bricolage = 'BricolageGrotesque';

  static List<FontVariation> _wght(FontWeight w) => [
    FontVariation('wght', w.value.toDouble()),
  ];

  /// Syne: wordmark, headings, button labels.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: syne,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Instrument Serif: references and editorial accents.
  static TextStyle serifText(
    double size, {
    bool italic = true,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: serif,
    fontSize: size,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: height,
  );

  /// Instrument Sans: body UI.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: sans,
    fontSize: size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    color: color,
    height: height,
    decoration: decoration,
    decorationColor: color,
  );

  static TextStyle cormorantText(
    double size, {
    bool italic = false,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: cormorant,
    fontSize: size,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: weight,
    fontVariations: _wght(weight),
    color: color,
    height: height,
  );

  static TextStyle monoText(
    double size, {
    bool bold = false,
    Color? color,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Bricolage Grotesque; [condensed] maps to the 75% width axis.
  static TextStyle grotesk(
    double size, {
    FontWeight weight = FontWeight.w700,
    bool condensed = false,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: bricolage,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [
      FontVariation('wght', weight.value.toDouble()),
      FontVariation('wdth', condensed ? 75 : 100),
      const FontVariation('opsz', 96),
    ],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
