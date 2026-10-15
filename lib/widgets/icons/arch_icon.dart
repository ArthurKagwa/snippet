import 'package:flutter/widgets.dart';

/// Arch outline glyph used for "All styles" (from the mockup's 24px icon).
class ArchIcon extends StatelessWidget {
  const ArchIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    return CustomPaint(
      size: Size.square(s),
      painter: _ArchPainter(color ?? theme.color!),
    );
  }
}

class _ArchPainter extends CustomPainter {
  const _ArchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final outer = Path()
      ..moveTo(4 * k, 21 * k)
      ..lineTo(4 * k, 11 * k)
      ..arcToPoint(Offset(20 * k, 11 * k), radius: Radius.circular(8 * k))
      ..lineTo(20 * k, 21 * k)
      ..close();
    final inner = Path()
      ..moveTo(9 * k, 21 * k)
      ..lineTo(9 * k, 15 * k)
      ..arcToPoint(Offset(15 * k, 15 * k), radius: Radius.circular(3 * k))
      ..lineTo(15 * k, 21 * k);
    canvas
      ..drawPath(outer, paint)
      ..drawPath(inner, paint);
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.color != color;
}
