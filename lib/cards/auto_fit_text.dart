import 'package:flutter/widgets.dart';

import 'marked_text.dart';

/// Text that picks the largest font size (up to [maxSize]) that fits the
/// available box, so long passages shrink instead of overflowing.
///
/// [styleFor] builds the style at a given size, which keeps letter spacing
/// proportional. Use inside a Flexible/Expanded so height is bounded.
/// With [highlight], each line gets a marker band (see [MarkedText]).
class AutoFitText extends StatelessWidget {
  const AutoFitText(
    this.text, {
    super.key,
    required this.styleFor,
    required this.maxSize,
    this.minSize = 6,
    this.textAlign = TextAlign.start,
    this.highlight,
    this.highlightPadding = EdgeInsets.zero,
  });

  final String text;
  final TextStyle Function(double size) styleFor;
  final double maxSize;
  final double minSize;
  final TextAlign textAlign;
  final Color? highlight;
  final EdgeInsets highlightPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _fit(constraints, Directionality.of(context));
        if (highlight case final color?) {
          return MarkedText(
            text,
            style: styleFor(size),
            color: color,
            padding: highlightPadding,
            textAlign: textAlign,
          );
        }
        return Text(
          text,
          textAlign: textAlign,
          textScaler: TextScaler.noScaling,
          style: styleFor(size),
        );
      },
    );
  }

  double _fit(BoxConstraints c, TextDirection dir) {
    if (!c.hasBoundedHeight || !c.hasBoundedWidth) return maxSize;
    bool fits(double size) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: styleFor(size)),
        textAlign: textAlign,
        textDirection: dir,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: c.maxWidth);
      final ok = painter.height <= c.maxHeight && !painter.didExceedMaxLines;
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
}
