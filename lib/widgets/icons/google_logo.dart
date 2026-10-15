import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_colors.dart';

/// Four-colour Google "G" for the sign-in button.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GooglePainter(context.colors),
  );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter(this.c);

  final SnippetColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;

    canvas
      ..drawArc(rect, deg(-40), deg(-100), false, arc(c.googleRed))
      ..drawArc(rect, deg(-140), deg(-80), false, arc(c.googleYellow))
      ..drawArc(rect, deg(-220), deg(-95), false, arc(c.googleGreen))
      ..drawArc(rect, deg(-315), deg(-45), false, arc(c.googleBlue))
      ..drawRect(
        Rect.fromLTRB(s / 2, s / 2 - stroke / 2, s, s / 2 + stroke / 2),
        Paint()..color = c.googleBlue,
      );
  }

  @override
  bool shouldRepaint(_GooglePainter old) => old.c != c;
}
