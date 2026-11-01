import 'package:flutter/widgets.dart';

import 'card_content.dart';

/// A verse reference that keeps every character.
///
/// One line when it fits at [size]. When the book name is too long to sit
/// beside its chapter and verse, those numbers move to the next line
/// instead of being clipped. The book itself may wrap on spaces, and the
/// size steps down toward [minSize], but the text is never ellipsized.
class VerseReference extends StatelessWidget {
  const VerseReference({
    super.key,
    required this.reference,
    required this.styleFor,
    required this.size,
    this.minSize = 7,
    this.translation = '',
    this.upper = false,
    this.textAlign = TextAlign.start,
  });

  final String reference;
  final TextStyle Function(double size) styleFor;
  final double size;
  final double minSize;
  final String translation;
  final bool upper;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final content = CardContent(
      text: '',
      reference: reference,
      translation: '',
    );
    final book = _case(content.referenceBook);
    final numbers = content.referenceNumbers;
    final tail = [
      if (numbers.isNotEmpty) numbers,
      if (translation.trim().isNotEmpty) translation.trim(),
    ].join(' · ');
    final oneLine = tail.isEmpty ? book : '$book $tail';

    TextStyle painted(double fontSize) {
      final style = styleFor(fontSize);
      if (!style.inherit) return style;
      return DefaultTextStyle.of(context).style.merge(style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double fit(String text, {int? maxLines}) {
          bool fits(double fontSize) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: painted(fontSize)),
              textAlign: textAlign,
              textDirection: direction,
              textScaler: TextScaler.noScaling,
              maxLines: maxLines,
            )..layout(maxWidth: width);
            final ok =
                !painter.didExceedMaxLines &&
                (!constraints.hasBoundedHeight ||
                    painter.height <= constraints.maxHeight);
            painter.dispose();
            return ok;
          }

          if (!width.isFinite || fits(size)) return size;
          var lo = minSize;
          var hi = size;
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

        var text = oneLine;
        var fontSize = fit(oneLine, maxLines: 1);
        // Stack only when one line had to shrink and two lines can be larger.
        if (tail.isNotEmpty && fontSize < size - 0.4) {
          final stacked = '$book\n$tail';
          final stackedSize = fit(stacked, maxLines: 2);
          if (stackedSize > fontSize + 0.4) {
            text = stacked;
            fontSize = stackedSize;
          }
        }
        return Text(
          text,
          textAlign: textAlign,
          textScaler: TextScaler.noScaling,
          softWrap: true,
          style: painted(fontSize),
        );
      },
    );
  }

  String _case(String value) => upper ? value.toUpperCase() : value;
}
