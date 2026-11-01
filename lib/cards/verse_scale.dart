import 'package:flutter/widgets.dart';

import '../core/theme/snippet_fonts.dart';
import 'card_content.dart';
import 'card_measure.dart';
import 'card_shape.dart';
import 'card_style_spec.dart';

/// How long a verse is, measured by laying it out rather than counting
/// characters. Tune [mediumFrom], [longFrom] and [longestFrom]: they are
/// line counts of the verse at [measureSize] across [measureWidth].
enum VerseBucket { short, medium, long, longest }

/// One style's type and spacing limits.
///
/// [maxSize] and [looseHeight] / [looseGap] / [loosePad] are the short-verse
/// end (big and airy). [minSize] and the tight values are the long-verse
/// end, and the floor used to decide whether the style can show the verse
/// at all. [storyWidth] and [storyHeight] are the verse column in the 9:16
/// card, in design units, at the tight spacing.
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
  });

  final double maxSize;
  final double minSize;
  final double looseHeight;
  final double tightHeight;
  final double looseGap;
  final double tightGap;
  final double loosePad;
  final double tightPad;
  final double storyWidth;
  final double storyHeight;
  final double squareWidth;
  final double squareHeight;
  final TextStyle Function(double size, double height) styleFor;

  VerseReading resolve(String text) {
    final bucket = VerseScales.bucketOf(text);
    final t = VerseScales.tightnessOf[bucket]!;
    return VerseReading(
      bucket: bucket,
      size: _lerp(maxSize, minSize, t),
      minSize: minSize,
      height: _lerp(looseHeight, tightHeight, t),
      gap: _lerp(looseGap, tightGap, t),
      pad: _lerp(loosePad, tightPad, t),
      spacing: VerseScales.spacingOf[bucket]!,
    );
  }

  /// Whether [text] still fits the story column at this style's minimum.
  bool fitsStory(String text) => _fits(text, storyWidth, storyHeight);

  /// Whether [text] fits the square column at the minimum.
  bool fitsSquare(String text) => _fits(text, squareWidth, squareHeight);

  /// Whether [text] fits an explicit column at this style's minimum.
  bool fitsBox(String text, double width, double height) =>
      _fits(text, width, height);

  bool _fits(String text, double width, double height) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    final painter = TextPainter(
      text: TextSpan(text: trimmed, style: styleFor(minSize, tightHeight)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);
    final ok = painter.height <= height + 0.5;
    painter.dispose();
    return ok;
  }

  static double _lerp(double loose, double tight, double t) =>
      loose + (tight - loose) * t;
}

/// The size and spacing a verse should use in one style.
class VerseReading {
  const VerseReading({
    required this.bucket,
    required this.size,
    required this.minSize,
    required this.height,
    required this.gap,
    required this.pad,
    required this.spacing,
  });

  final VerseBucket bucket;
  final double size;
  final double minSize;
  final double height;
  final double gap;
  final double pad;

  /// Multiplier for remote-layout gaps and vertical padding. 1 is the
  /// spacing as written in the layout; short verses sit above it, long
  /// ones below.
  final double spacing;
}

/// Per-style caps and the shared length buckets. This is the place to tune.
abstract final class VerseScales {
  /// Line measure shared by every style, so the bucket (and therefore the
  /// type size and the gaps) does not change as you swipe. Which export
  /// sizes are offered is measured per style, not taken from the bucket.
  static const measureWidth = 236.0;
  static const measureSize = 18.0;
  static const measureHeight = 1.2;

  /// Line counts at the measure above.
  static const mediumFrom = 4;
  static const longFrom = 7;
  static const longestFrom = 11;

  static const tightnessOf = {
    VerseBucket.short: 0.0,
    VerseBucket.medium: 0.35,
    VerseBucket.long: 0.68,
    VerseBucket.longest: 1.0,
  };

  static const spacingOf = {
    VerseBucket.short: 1.14,
    VerseBucket.medium: 1.0,
    VerseBucket.long: 0.84,
    VerseBucket.longest: 0.70,
  };

  static final Map<String, StyleTypeScale> byId = {
    'vigil': StyleTypeScale(
      maxSize: 30,
      minSize: 16,
      looseHeight: 1.32,
      tightHeight: 1.08,
      looseGap: 26,
      tightGap: 12,
      loosePad: 52,
      tightPad: 30,
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
      minSize: 15,
      looseHeight: 1.28,
      tightHeight: 1.06,
      looseGap: 22,
      tightGap: 10,
      loosePad: 56,
      tightPad: 32,
      storyWidth: 230,
      storyHeight: 350,
      squareWidth: 230,
      squareHeight: 148,
      styleFor: (s, h) => SnippetFonts.cormorantText(s, height: h),
    ),
    'night-watch': StyleTypeScale(
      maxSize: 34,
      minSize: 17,
      looseHeight: 1.16,
      tightHeight: 1.0,
      looseGap: 26,
      tightGap: 12,
      loosePad: 44,
      tightPad: 26,
      storyWidth: 230,
      storyHeight: 370,
      squareWidth: 230,
      squareHeight: 156,
      styleFor: (s, h) => SnippetFonts.serifText(s, italic: false, height: h),
    ),
    'swiss': StyleTypeScale(
      maxSize: 36,
      minSize: 16,
      looseHeight: 1.04,
      tightHeight: 0.92,
      looseGap: 26,
      tightGap: 12,
      loosePad: 40,
      tightPad: 22,
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
      minSize: 18,
      looseHeight: 0.96,
      tightHeight: 0.86,
      looseGap: 26,
      tightGap: 12,
      loosePad: 36,
      tightPad: 20,
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
      minSize: 15,
      looseHeight: 1.2,
      tightHeight: 1.02,
      looseGap: 22,
      tightGap: 10,
      loosePad: 28,
      tightPad: 16,
      storyWidth: 200,
      storyHeight: 340,
      squareWidth: 200,
      squareHeight: 140,
      styleFor: (s, h) => SnippetFonts.serifText(s, height: h),
    ),
    'psalter': StyleTypeScale(
      maxSize: 30,
      minSize: 15,
      looseHeight: 1.28,
      tightHeight: 1.08,
      looseGap: 18,
      tightGap: 8,
      loosePad: 32,
      tightPad: 20,
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
      minSize: 20,
      looseHeight: 0.98,
      tightHeight: 0.86,
      looseGap: 28,
      tightGap: 14,
      loosePad: 36,
      tightPad: 22,
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
      minSize: 13,
      looseHeight: 1.95,
      tightHeight: 1.48,
      looseGap: 16,
      tightGap: 8,
      loosePad: 40,
      tightPad: 24,
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
    minSize: 14,
    looseHeight: 1.24,
    tightHeight: 1.05,
    looseGap: 20,
    tightGap: 10,
    loosePad: 36,
    tightPad: 22,
    storyWidth: 230,
    storyHeight: 340,
    squareWidth: 230,
    squareHeight: 150,
    styleFor: (s, h) => SnippetFonts.cormorantText(s, height: h),
  );

  static StyleTypeScale of(String id) => byId[id] ?? fallback;

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

  static VerseBucket bucketOf(String text) {
    final lines = lineCount(text);
    if (lines >= longestFrom) return VerseBucket.longest;
    if (lines >= longFrom) return VerseBucket.long;
    if (lines >= mediumFrom) return VerseBucket.medium;
    return VerseBucket.short;
  }

  /// Shapes whose verse well can hold [content] in [style] at the scaled
  /// font. A size is left out only when the text overruns that well by
  /// more than [CardMeasure.slack]. When nothing fits, story stays so the
  /// export sheet is never empty.
  static List<CardShape> exportShapes(
    CardStyleSpec style,
    CardContent content,
  ) {
    final offered = [
      for (final shape in CardShape.values)
        if (_offers(style, content, shape)) shape,
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

  static bool _offers(
    CardStyleSpec style,
    CardContent content,
    CardShape shape,
  ) {
    final reading = read(style.id, content.text);
    return CardMeasure.offers(
      style: style,
      content: content,
      shape: shape,
      fontSize: reading.size,
      lineHeight: reading.height,
      fallback: () => _columnFits(style.id, content.text, shape),
    );
  }

  /// Column check for a style whose card does not draw the verse (tests,
  /// and a layout that failed to measure). Uses the declared text column.
  static bool _columnFits(String id, String text, CardShape shape) {
    final scale = of(id);
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
    return scale.fitsBox(text, width, height);
  }

  /// Styles whose story frame can still hold [content]. When none can,
  /// the full list is returned so the screen is never empty.
  static List<CardStyleSpec> stylesForVerse(
    List<CardStyleSpec> styles,
    CardContent content,
  ) {
    final offered = [
      for (final style in styles)
        if (_offers(style, content, CardShape.story)) style,
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
