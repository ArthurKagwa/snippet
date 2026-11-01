import 'package:flutter/widgets.dart';

/// Text with a highlighter band behind each line, leaving the line gaps
/// clear, like a marker run over a printed page.
///
/// Bands hug the glyphs (font ascent to descent, ignoring the style's
/// `height`), so a taller line height opens a gap between them. [padding]
/// grows each band past its line.
class MarkedText extends StatelessWidget {
  const MarkedText(
    this.text, {
    super.key,
    required this.style,
    required this.color,
    this.padding = EdgeInsets.zero,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final EdgeInsets padding;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BandPainter(
      text: text,
      style: style,
      color: color,
      padding: padding,
      textAlign: textAlign,
      direction: Directionality.of(context),
      maxLines: maxLines,
    ),
    child: Text(
      text,
      textAlign: textAlign,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
      style: style,
    ),
  );
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.text,
    required this.style,
    required this.color,
    required this.padding,
    required this.textAlign,
    required this.direction,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final EdgeInsets padding;
  final TextAlign textAlign;
  final TextDirection direction;
  final int? maxLines;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: direction,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
    )..layout(maxWidth: size.width);
    // One unscaled line gives the glyph ascent and descent.
    final glyphs = TextPainter(
      text: TextSpan(text: 'Hg', style: style.copyWith(height: 1)),
      textDirection: direction,
      textScaler: TextScaler.noScaling,
    )..layout();
    final [probe] = glyphs.computeLineMetrics();
    final paint = Paint()..color = color;
    for (final line in lines.computeLineMetrics()) {
      if (line.width <= 0) continue;
      canvas.drawRect(
        Rect.fromLTRB(
          line.left - padding.left,
          line.baseline - probe.ascent - padding.top,
          line.left + line.width + padding.right,
          line.baseline + probe.descent + padding.bottom,
        ),
        paint,
      );
    }
    lines.dispose();
    glyphs.dispose();
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.text != text ||
      old.style != style ||
      old.color != color ||
      old.padding != padding ||
      old.textAlign != textAlign ||
      old.direction != direction ||
      old.maxLines != maxLines;
}
