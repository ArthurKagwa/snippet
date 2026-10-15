import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import 'halftone_painter.dart';

/// Riso Loud: poster type, heavy outline, tilted reference tag.
class RisoCard extends StatelessWidget {
  const RisoCard({
    super.key,
    required this.content,
    required this.palette,
    required this.shape,
  });

  final CardContent content;
  final CardPalette palette;
  final CardShape shape;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.border, width: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: HalftonePainter(
              color: palette.border.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: -3 * math.pi / 180,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.border, width: 1.7),
                    ),
                    child: Text(
                      content.referenceLine,
                      textScaler: TextScaler.noScaling,
                      style: SnippetFonts.monoText(
                        9.3,
                        bold: true,
                        color: palette.surfaceInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: AutoFitText(
                      content.text.toUpperCase(),
                      maxSize: 34,
                      styleFor: (s) => SnippetFonts.grotesk(
                        s,
                        weight: FontWeight.w800,
                        condensed: true,
                        color: palette.ink,
                        height: 0.9,
                        letterSpacing: -s * 0.021,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
