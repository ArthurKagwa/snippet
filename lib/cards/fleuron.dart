import 'package:flutter/widgets.dart';

/// A small floral heart, drawn rather than set in type.
///
/// Cormorant has no U+2767, so a text fleuron paints a missing-glyph box.
/// The mark stays inside [extent] and never hangs into the verse below it.
class Fleuron extends StatelessWidget {
  const Fleuron({super.key, required this.color, required this.extent});

  final Color color;

  /// Height of the ornament. Width is a little more than twice that.
  final double extent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extent * 2.4,
      height: extent,
      child: CustomPaint(painter: _FleuronPainter(color)),
    );
  }
}

class _FleuronPainter extends CustomPainter {
  const _FleuronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.height * 0.12, paint);
    canvas.drawPath(_wing(size, 1), paint);
    canvas.drawPath(_wing(size, -1), paint);
  }

  Path _wing(Size size, double direction) {
    final width = size.width;
    final height = size.height;
    final cx = width / 2;
    final cy = height / 2;
    return Path()
      ..moveTo(cx + direction * height * 0.14, cy)
      ..cubicTo(
        cx + direction * width * 0.26,
        cy - height * 0.62,
        cx + direction * width * 0.46,
        cy - height * 0.18,
        cx + direction * width * 0.44,
        cy + height * 0.02,
      )
      ..cubicTo(
        cx + direction * width * 0.34,
        cy + height * 0.34,
        cx + direction * width * 0.16,
        cy + height * 0.26,
        cx + direction * height * 0.1,
        cy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_FleuronPainter old) => old.color != color;
}
