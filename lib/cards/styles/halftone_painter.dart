import 'package:flutter/rendering.dart';

/// Even dot grid, like a riso halftone screen.
class HalftonePainter extends CustomPainter {
  const HalftonePainter({
    required this.color,
    this.spacing = 10,
    this.radius = 0.9,
  });

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HalftonePainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}
