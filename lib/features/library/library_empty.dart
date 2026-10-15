import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/pill_button.dart';

/// "Nothing saved yet": dashed arch with the lime sun.
class LibraryEmpty extends StatelessWidget {
  const LibraryEmpty({super.key, required this.onPickVerse});

  final VoidCallback onPickVerse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 184,
                  height: 187,
                  child: CustomPaint(
                    painter: _DashedArch(c.archLine),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.lime,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Nothing saved yet',
                  textAlign: TextAlign.center,
                  style: SnippetFonts.display(
                    26.7,
                    color: c.white,
                    letterSpacing: -1,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the bookmark while you swipe and the card will wait '
                  'for you here.',
                  textAlign: TextAlign.center,
                  style: SnippetFonts.body(13.3, color: c.mist, height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    key: const Key('pick-a-verse'),
                    label: 'Pick a verse',
                    onPressed: onPickVerse,
                    background: c.lime,
                    foreground: c.ink,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedArch extends CustomPainter {
  const _DashedArch(this.line);

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const archWidth = 144.0;
    final left = (size.width - archWidth) / 2;
    final r = archWidth / 2;
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(left, size.height)
      ..lineTo(left, r)
      ..arcToPoint(Offset(left + archWidth, r), radius: Radius.circular(r))
      ..lineTo(left + archWidth, size.height);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DashedArch old) => old.line != line;
}
