import 'package:flutter/widgets.dart';

import 'text_fit.dart';

/// A verse reference set as display type: "PSALM 46:10" on one line, or
/// the book name over its chapter:verse when the two will not sit on one
/// line at [maxSize].
///
/// The chapter and verse are never dropped. One line is preferred, and the
/// break is always taken between the book and its numbers — never inside
/// either — so "1 THESSALONIANS" never splits after the "1".
class ReferenceText extends StatelessWidget {
  const ReferenceText({
    super.key,
    required this.book,
    required this.numbers,
    required this.styleFor,
    required this.maxSize,
    this.minSize = 6,
    this.textAlign = TextAlign.start,
  });

  /// "Song of Solomon", already cased the way it should be drawn.
  final String book;

  /// "1:1", or empty for a reference with no chapter:verse.
  final String numbers;

  final TextStyle Function(double size) styleFor;
  final double maxSize;
  final double minSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    TextStyle painted(double size) => paintedStyle(context, styleFor(size));
    final oneLine = numbers.isEmpty ? book : '$book $numbers';
    return LayoutBuilder(
      builder: (context, constraints) {
        double fit(String text, int lines) => fitTextSize(
          text,
          styleFor: painted,
          box: constraints,
          maxSize: maxSize,
          minSize: minSize,
          textAlign: textAlign,
          direction: direction,
          maxLines: lines,
        );

        var text = oneLine;
        var lines = 1;
        var size = fit(oneLine, 1);
        // Only stack when one line costs size and stacking buys it back.
        if (numbers.isNotEmpty && size < maxSize) {
          final stacked = '$book\n$numbers';
          final stackedSize = fit(stacked, 2);
          if (stackedSize > size) {
            text = stacked;
            lines = 2;
            size = stackedSize;
          }
        }
        return Text(
          text,
          textAlign: textAlign,
          textScaler: TextScaler.noScaling,
          // Two lines are capped; one line is left free to wrap, so a
          // reference that somehow still will not fit spills onto a second
          // line instead of having its tail clipped off.
          maxLines: lines == 2 ? 2 : null,
          style: painted(size),
        );
      },
    );
  }
}
