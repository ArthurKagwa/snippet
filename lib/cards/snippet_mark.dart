import 'package:flutter/widgets.dart';

import '../core/theme/snippet_fonts.dart';

/// The export watermark: the monochrome app icon (outlined arch, solid sun,
/// from assets/icon/monochrome.svg) beside the wordmark, in one ink colour.
class SnippetMark extends StatelessWidget {
  const SnippetMark({super.key, required this.color, this.size = 8});

  final Color color;

  /// Wordmark font size in design units; the glyph is sized to match.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size.square(size * 1.05),
          painter: _MonochromeIconPainter(color),
        ),
        SizedBox(width: size * 0.3),
        Text(
          'snippet',
          textScaler: TextScaler.noScaling,
          style: SnippetFonts.display(
            size,
            color: color,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// monochrome.svg cropped to the glyph: on its 108 canvas the arch spans
/// x 36–72 with its crown at y 39.375 and the sun sits at (54, 55.5).
class _MonochromeIconPainter extends CustomPainter {
  const _MonochromeIconPainter(this.color);

  final Color color;

  static const double _stroke = 2.25;
  static const double _box = 36 + _stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _box;
    const half = _stroke / 2;
    final arch = Path()
      ..moveTo(half * k, size.height)
      ..lineTo(half * k, (18 + half) * k)
      ..arcToPoint(
        Offset((36 + half) * k, (18 + half) * k),
        radius: Radius.circular(18 * k),
      )
      ..lineTo((36 + half) * k, size.height);
    canvas
      ..drawPath(
        arch,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke * k,
      )
      ..drawCircle(
        Offset((18 + half) * k, (55.5 - 39.375 + half) * k),
        7.5 * k,
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(_MonochromeIconPainter old) => old.color != color;
}
