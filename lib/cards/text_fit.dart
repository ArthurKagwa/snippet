import 'package:flutter/widgets.dart';

/// The style a [Text] will really paint with.
///
/// [Text] merges the ambient [DefaultTextStyle] into any style that still
/// inherits, so a card inside a [Material] picks up the theme's body style
/// — letter spacing and all. Measuring the bare style would under-measure
/// the painted line, and a fitted size worked out that way overflows.
TextStyle paintedStyle(BuildContext context, TextStyle style) =>
    style.inherit ? DefaultTextStyle.of(context).style.merge(style) : style;

/// The largest size between [minSize] and [maxSize] whose text fits [box]
/// in at most [maxLines] lines.
///
/// Pass the same `styleFor` the text is painted with (see [paintedStyle]).
/// Returns [minSize] when even that overflows, which is the caller's cue
/// that the box is too small for the text.
double fitTextSize(
  String text, {
  required TextStyle Function(double size) styleFor,
  required BoxConstraints box,
  required double maxSize,
  required double minSize,
  required TextAlign textAlign,
  required TextDirection direction,
  int? maxLines,
}) {
  if (!box.hasBoundedWidth) return maxSize;

  bool fits(double size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: styleFor(size)),
      textAlign: textAlign,
      textDirection: direction,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
    )..layout(maxWidth: box.maxWidth);
    final ok =
        (!box.hasBoundedHeight || painter.height <= box.maxHeight) &&
        !painter.didExceedMaxLines;
    painter.dispose();
    return ok;
  }

  if (fits(maxSize)) return maxSize;
  var lo = minSize;
  var hi = maxSize;
  for (var i = 0; i < 12; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}
