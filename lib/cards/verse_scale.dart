import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/theme/snippet_fonts.dart';
import 'card_content.dart';
import 'card_measure.dart';
import 'card_shape.dart';
import 'card_style_spec.dart';

/// One style's type and spacing limits.
///
/// [maxSize], [looseHeight], [looseGap], [loosePad] and [looseSpacing] are
/// the short-verse end (big and airy). [minSize] and the tight values are
/// the floor: still legible, and the point past which an export size is
/// hidden. Body floors stay at about 12 logical pixels and a line height of
/// 1.15. Display-caps styles (Marquee, Riso Loud) may use a tighter leading.
/// [storyWidth] / [storyHeight] and the square pair are the verse column in
/// design units, used only when a card cannot be measured.
class StyleTypeScale {
  const StyleTypeScale({
    required this.maxSize,
    required this.minSize,
    required this.looseHeight,
    required this.tightHeight,
    required this.looseGap,
    required this.tightGap,
    required this.loosePad,
    required this.tightPad,
    required this.storyWidth,
    required this.storyHeight,
    required this.squareWidth,
    required this.squareHeight,
    required this.styleFor,
    this.looseSpacing = VerseScales.looseSpacing,
    this.tightSpacing = VerseScales.tightSpacing,
  });

  final double maxSize;
  final double minSize;
  final double looseHeight;
  final double tightHeight;
  final double looseGap;
  final double tightGap;
  final double loosePad;
  final double tightPad;
  final double looseSpacing;
  final double tightSpacing;
  final double storyWidth;
  final double storyHeight;
  final double squareWidth;
  final double squareHeight;
  final TextStyle Function(double size, double height) styleFor;

  /// [t] is 0 at the short-verse end and 1 at the floor.
  VerseReading at(double t, {bool fits = true}) {
    final clamped = t.clamp(0.0, 1.0);
    return VerseReading(
      tightness: clamped,
      size: _lerp(maxSize, minSize, clamped),
      minSize: minSize,
      height: _lerp(looseHeight, tightHeight, clamped),
      gap: _lerp(looseGap, tightGap, clamped),
      pad: _lerp(loosePad, tightPad, clamped),
      spacing: _lerp(looseSpacing, tightSpacing, clamped),
      looseSpacing: looseSpacing,
      fits: fits,
    );
  }

  /// Length-driven reading, before a shape asks for a tighter fit.
  VerseReading resolve(String text) => at(VerseScales.lengthTightness(text));

  /// Whether [text] still fits the story column at this style's floor.
  bool fitsStory(String text) => _fits(text, storyWidth, storyHeight);

  /// Whether [text] fits the square column at the floor.
  bool fitsSquare(String text) => _fits(text, squareWidth, squareHeight);

  /// Whether [text] fits an explicit column. Defaults to the floor.
  bool fitsBox(
    String text,
    double width,
    double height, {
    double? size,
    double? lineHeight,
  }) => _fits(text, width, height, size: size, lineHeight: lineHeight);

  bool _fits(
    String text,
    double width,
    double height, {
    double? size,
    double? lineHeight,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    final painter = TextPainter(
      text: TextSpan(
        text: trimmed,
        style: styleFor(size ?? minSize, lineHeight ?? tightHeight),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);
    final ok = painter.height <= height * (1 + CardMeasure.slack) + 0.5;
    painter.dispose();
    return ok;
  }

  StyleTypeScale copyWith({double? minSize, double? tightHeight}) {
    final floor = math.min(minSize ?? this.minSize, maxSize);
    final leading = math.min(tightHeight ?? this.tightHeight, looseHeight);
    return StyleTypeScale(
      maxSize: maxSize,
      minSize: floor,
      looseHeight: looseHeight,
      tightHeight: leading,
      looseGap: looseGap,
      tightGap: tightGap,
      loosePad: loosePad,
      tightPad: tightPad,
      looseSpacing: looseSpacing,
      tightSpacing: tightSpacing,
      storyWidth: storyWidth,
      storyHeight: storyHeight,
      squareWidth: squareWidth,
      squareHeight: squareHeight,
      styleFor: styleFor,
    );
  }

  static double _lerp(double loose, double tight, double t) =>
      loose + (tight - loose) * t;
}

/// The size and spacing a verse should use in one style.
class VerseReading {
  const VerseReading({
    required this.tightness,
    required this.size,
    required this.minSize,
    required this.height,
    required this.gap,
    required this.pad,
    required this.spacing,
    required this.looseSpacing,
    this.fits = true,
  });

  /// 0 is the short-verse end of the style. 1 is the floor.
  final double tightness;
  final double size;
  final double minSize;
  final double height;
  final double gap;
  final double pad;

  /// Multiplier for remote-layout gaps and vertical padding. 1 is the
  /// spacing as written in the layout; short verses sit above it, long
  /// ones below.
  final double spacing;

  /// [spacing] at [tightness] 0. Padding that the length scale did not
  /// previously touch divides by this so a short verse stays put.
  final double looseSpacing;

  /// Whether this reading fits the shape it was solved for.
  final bool fits;

  /// A length that is [loose] for a short verse and [tight] at the floor.
  double span(double loose, double tight) =>
      loose + (tight - loose) * tightness;
}

/// Per-style caps and the continuous length curve. This is the place to tune.
///
/// Font size, line height, gaps and padding move together along each style's
/// curve. [read] places a verse on that curve from its measured line count.
/// [forShape] then keeps the largest size on the curve that fits one export
/// shape, searching down to the floor. A size is hidden only when the floor
/// still overflows, with [CardMeasure.slack] of room past the well.
abstract final class VerseScales {
  /// Line measure shared by every style, so the length curve (and therefore
  /// the preferred type) does not change as you swipe. Which export sizes
  /// are offered is measured per style and per shape.
  static const measureWidth = 236.0;
  static const measureSize = 18.0;
  static const measureHeight = 1.2;

  /// Where the old buckets sat, kept so the curve passes through them
  /// instead of jumping.
  static const mediumFrom = 4;
  static const longFrom = 7;
  static const longestFrom = 11;

  /// Remote-layout spacing at the two ends of every curve. Short verses
  /// keep the old 1.14; the floor compresses further than the old 0.70.
  static const looseSpacing = 1.14;
  static const tightSpacing = 0.50;

  static final Map<String, StyleTypeScale> byId = {
    'vigil': StyleTypeScale(
      maxSize: 30,
      minSize: 12,
      looseHeight: 1.32,
      tightHeight: 1.15,
      looseGap: 26,
      tightGap: 4,
      loosePad: 52,
      tightPad: 16,
      storyWidth: 214,
      storyHeight: 360,
      squareWidth: 214,
      squareHeight: 150,
      styleFor: (s, h) => SnippetFonts.cormorantText(
        s,
        italic: true,
        weight: FontWeight.w400,
        height: h,
      ),
    ),
    'dawn': StyleTypeScale(
      maxSize: 28,
      minSize: 12,
      looseHeight: 1.28,
      tightHeight: 1.15,
      looseGap: 22,
      tightGap: 4,
      loosePad: 56,
      tightPad: 16,
      storyWidth: 230,
      storyHeight: 350,
      squareWidth: 230,
      squareHeight: 148,
      styleFor: (s, h) => SnippetFonts.cormorantText(s, height: h),
    ),
    'night-watch': StyleTypeScale(
      maxSize: 34,
      minSize: 12,
      looseHeight: 1.16,
      tightHeight: 1.15,
      looseGap: 26,
      tightGap: 4,
      loosePad: 44,
      tightPad: 14,
      storyWidth: 230,
      storyHeight: 370,
      squareWidth: 230,
      squareHeight: 156,
      styleFor: (s, h) => SnippetFonts.serifText(s, italic: false, height: h),
    ),
    'swiss': StyleTypeScale(
      maxSize: 36,
      minSize: 12,
      looseHeight: 1.04,
      tightHeight: 1.0,
      looseGap: 26,
      tightGap: 4,
      loosePad: 40,
      tightPad: 12,
      storyWidth: 240,
      storyHeight: 380,
      squareWidth: 240,
      squareHeight: 160,
      styleFor: (s, h) => SnippetFonts.grotesk(
        s,
        weight: FontWeight.w700,
        height: h,
        letterSpacing: -s * 0.034,
      ),
    ),
    'riso': StyleTypeScale(
      maxSize: 42,
      minSize: 12,
      looseHeight: 0.96,
      tightHeight: 0.82,
      looseGap: 26,
      tightGap: 4,
      loosePad: 36,
      tightPad: 8,
      storyWidth: 246,
      storyHeight: 360,
      squareWidth: 246,
      squareHeight: 150,
      styleFor: (s, h) => SnippetFonts.grotesk(
        s,
        weight: FontWeight.w800,
        condensed: true,
        height: h,
        letterSpacing: -s * 0.021,
      ),
    ),
    'cobalt-arch': StyleTypeScale(
      maxSize: 28,
      minSize: 11,
      looseHeight: 1.2,
      tightHeight: 1.15,
      looseGap: 22,
      tightGap: 2,
      loosePad: 28,
      tightPad: 8,
      storyWidth: 200,
      storyHeight: 340,
      squareWidth: 200,
      squareHeight: 140,
      styleFor: (s, h) => SnippetFonts.serifText(s, height: h),
    ),
    'psalter': StyleTypeScale(
      maxSize: 30,
      minSize: 12,
      looseHeight: 1.28,
      tightHeight: 1.15,
      looseGap: 18,
      tightGap: 4,
      loosePad: 32,
      tightPad: 8,
      storyWidth: 220,
      storyHeight: 340,
      squareWidth: 220,
      squareHeight: 140,
      styleFor: (s, h) => SnippetFonts.cormorantText(
        s,
        italic: true,
        weight: FontWeight.w500,
        height: h,
      ),
    ),
    'marquee': StyleTypeScale(
      maxSize: 48,
      minSize: 12,
      looseHeight: 0.98,
      tightHeight: 0.80,
      looseGap: 28,
      tightGap: 4,
      loosePad: 36,
      tightPad: 8,
      storyWidth: 246,
      storyHeight: 340,
      squareWidth: 246,
      squareHeight: 140,
      styleFor: (s, h) => SnippetFonts.grotesk(
        s,
        weight: FontWeight.w800,
        condensed: true,
        height: h,
        letterSpacing: -s * 0.02,
      ),
    ),
    'highlight': StyleTypeScale(
      maxSize: 24,
      minSize: 12,
      looseHeight: 1.95,
      tightHeight: 1.20,
      looseGap: 16,
      tightGap: 4,
      loosePad: 40,
      tightPad: 12,
      storyWidth: 236,
      storyHeight: 320,
      squareWidth: 236,
      squareHeight: 130,
      styleFor: (s, h) =>
          SnippetFonts.cormorantText(s, weight: FontWeight.w500, height: h),
    ),
  };

  static final fallback = StyleTypeScale(
    maxSize: 26,
    minSize: 12,
    looseHeight: 1.24,
    tightHeight: 1.15,
    looseGap: 20,
    tightGap: 4,
    loosePad: 36,
    tightPad: 12,
    storyWidth: 230,
    storyHeight: 340,
    squareWidth: 230,
    squareHeight: 150,
    styleFor: (s, h) => SnippetFonts.cormorantText(s, height: h),
  );

  /// Floors supplied by a remote layout (`minFontSize`, `minLineHeight`).
  static final Map<String, StyleTypeScale> layoutLimits = {};

  static VerseReading? _probe;
  static final Map<String, VerseReading> _fitCache = {};

  static StyleTypeScale of(String id) =>
      layoutLimits[id] ?? byId[id] ?? fallback;

  /// Drops remote floors and fitted-size cache. Bundled scales stay.
  static void resetLayoutLimits() {
    layoutLimits.clear();
    _fitCache.clear();
  }

  /// Lowers [id]'s floor from a remote text node. Unknown styles use
  /// [fallback]. A floor never exceeds the style's loose end.
  static void applyTextLimits(
    String id, {
    double? minFontSize,
    double? minLineHeight,
  }) {
    if (minFontSize == null && minLineHeight == null) return;
    layoutLimits[id] = of(id)
        .copyWith(minSize: minFontSize, tightHeight: minLineHeight);
    _fitCache.clear();
  }

  /// Length-driven reading. Cards that know their shape use [forShape].
  static VerseReading read(String id, String text) => of(id).resolve(text);

  static int lineCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 1;
    final painter = TextPainter(
      text: TextSpan(
        text: trimmed,
        style: SnippetFonts.cormorantText(measureSize, height: measureHeight),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: measureWidth);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines;
  }

  /// 0 for a short verse, 1 once the verse is past the old longest bucket,
  /// and a smooth step between. Line counts are the shared measure above.
  static double lengthTightness(String text) => _tightnessFor(lineCount(text));

  static double _tightnessFor(int lines) {
    if (lines < mediumFrom) return 0;
    if (lines < longFrom) {
      return _smooth((lines - (mediumFrom - 1)) / (longFrom - mediumFrom)) *
          0.35;
    }
    if (lines < longestFrom) {
      return 0.35 +
          _smooth((lines - (longFrom - 1)) / (longestFrom - longFrom)) *
              (0.68 - 0.35);
    }
    const settleAt = 16;
    if (lines >= settleAt) return 1;
    return 0.68 +
        _smooth((lines - (longestFrom - 1)) / (settleAt - longestFrom)) *
            (1 - 0.68);
  }

  static double _smooth(double u) {
    final x = u.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// Largest type on this style's curve that fits [content] in [shape].
  ///
  /// The search moves font size, line height, gaps and padding together.
  /// [VerseReading.fits] is false only when the floor still overflows.
  /// While a measurement is in progress the card under test is built with
  /// the candidate, so the well and the type stay in step.
  static VerseReading forShape(
    CardStyleSpec style,
    CardContent content,
    CardShape shape,
  ) {
    final probed = _probe;
    if (probed != null) return probed;
    final scale = of(style.id);
    final key = _fitKey(style, content, shape, scale);
    final cached = _fitCache[key];
    if (cached != null) return cached;

    bool fits(VerseReading reading) {
      _probe = reading;
      try {
        return CardMeasure.offers(
          style: style,
          content: content,
          shape: shape,
          fontSize: reading.size,
          lineHeight: reading.height,
          gap: reading.gap,
          pad: reading.pad,
          spacing: reading.spacing,
          fallback: () => _columnFits(scale, content.text, shape, reading),
        );
      } finally {
        _probe = null;
      }
    }

    final loose = scale.at(0);
    final VerseReading solved;
    if (fits(loose)) {
      solved = loose;
    } else {
      final floor = scale.at(1);
      if (!fits(floor)) {
        solved = scale.at(1, fits: false);
      } else {
        var lo = 0.0;
        var hi = 1.0;
        for (var i = 0; i < 10; i++) {
          final mid = (lo + hi) / 2;
          if (fits(scale.at(mid))) {
            hi = mid;
          } else {
            lo = mid;
          }
        }
        solved = scale.at(hi);
      }
    }
    _fitCache[key] = solved;
    return solved;
  }

  static String _fitKey(
    CardStyleSpec style,
    CardContent content,
    CardShape shape,
    StyleTypeScale scale,
  ) =>
      '${style.id}|${identityHashCode(style.builder)}|${shape.name}|'
      '${content.text}|${content.reference}|${content.translation}|'
      '${scale.maxSize}|${scale.minSize}|${scale.looseHeight}|'
      '${scale.tightHeight}|${scale.looseGap}|${scale.tightGap}|'
      '${scale.loosePad}|${scale.tightPad}|${scale.looseSpacing}|'
      '${scale.tightSpacing}';

  /// Shapes whose verse well can hold [content] in [style]. A size is left
  /// out only when the text overruns that well at the floor by more than
  /// [CardMeasure.slack]. When nothing fits, story stays so the export
  /// sheet is never empty.
  static List<CardShape> exportShapes(
    CardStyleSpec style,
    CardContent content,
  ) {
    final offered = [
      for (final shape in CardShape.values)
        if (forShape(style, content, shape).fits) shape,
    ];
    return offered.isEmpty ? const [CardShape.story] : offered;
  }

  /// The swipe card: 4:5 when it fits, otherwise the story, otherwise the
  /// square. Each style is measured on its own.
  static CardShape previewShape(CardStyleSpec style, CardContent content) {
    final shapes = exportShapes(style, content);
    if (shapes.contains(CardShape.portrait)) return CardShape.portrait;
    if (shapes.contains(CardShape.story)) return CardShape.story;
    return CardShape.feed;
  }

  /// Column check for a style whose card does not draw the verse (tests,
  /// and a layout that failed to measure). Uses the declared text column.
  static bool _columnFits(
    StyleTypeScale scale,
    String text,
    CardShape shape,
    VerseReading reading,
  ) {
    final (width, height) = switch (shape) {
      CardShape.feed => (scale.squareWidth, scale.squareHeight),
      CardShape.story => (scale.storyWidth, scale.storyHeight),
      CardShape.portrait => (
        scale.squareWidth < scale.storyWidth
            ? scale.squareWidth
            : scale.storyWidth,
        (scale.squareHeight + scale.storyHeight) / 2,
      ),
    };
    return scale.fitsBox(
      text,
      width,
      height,
      size: reading.size,
      lineHeight: reading.height,
    );
  }

  /// Styles whose story frame can still hold [content]. When none can,
  /// the full list is returned so the screen is never empty.
  static List<CardStyleSpec> stylesForVerse(
    List<CardStyleSpec> styles,
    CardContent content,
  ) {
    final offered = [
      for (final style in styles)
        if (forShape(style, content, CardShape.story).fits) style,
    ];
    return offered.isEmpty ? styles : offered;
  }

  /// Index of [id] in [styles], or the first style when [id] is absent
  /// (it was hidden because the verse does not fit it).
  static int indexOfStyle(List<CardStyleSpec> styles, String? id) {
    if (styles.isEmpty) return 0;
    final i = styles.indexWhere((s) => s.id == id);
    return i < 0 ? 0 : i;
  }
}
