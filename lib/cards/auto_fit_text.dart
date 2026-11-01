import 'package:flutter/widgets.dart';

import 'marked_text.dart';
import 'text_fit.dart';

/// Text that picks the largest font size (up to [maxSize]) that fits the
/// available box, so long passages shrink instead of overflowing.
///
/// [styleFor] builds the style at a given size, which keeps letter spacing
/// proportional. Use inside a Flexible/Expanded so height is bounded, or
/// give [maxLines] so the line count bounds it instead.
/// With [highlight], each line gets a marker band (see [MarkedText]).
class AutoFitText extends StatelessWidget {
  const AutoFitText(
    this.text, {
    super.key,
    required this.styleFor,
    required this.maxSize,
    this.minSize = 6,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.highlight,
    this.highlightPadding = EdgeInsets.zero,
  });

  final String text;
  final TextStyle Function(double size) styleFor;
  final double maxSize;
  final double minSize;
  final TextAlign textAlign;
  final int? maxLines;
  final Color? highlight;
  final EdgeInsets highlightPadding;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    // Fit what will actually be painted, theme and all.
    TextStyle painted(double size) => paintedStyle(context, styleFor(size));
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = painted(
          fitTextSize(
            text,
            styleFor: painted,
            box: constraints,
            maxSize: maxSize,
            minSize: minSize,
            textAlign: textAlign,
            direction: direction,
            maxLines: maxLines,
          ),
        );
        if (highlight case final color?) {
          return MarkedText(
            text,
            style: style,
            color: color,
            padding: highlightPadding,
            textAlign: textAlign,
            maxLines: maxLines,
          );
        }
        return Text(
          text,
          textAlign: textAlign,
          textScaler: TextScaler.noScaling,
          maxLines: maxLines,
          style: style,
        );
      },
    );
  }
}
