import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';
import 'halftone_painter.dart';

/// Riso Loud: poster type, heavy outline, tilted reference tag.
class RisoCard extends StatelessWidget {
  const RisoCard({
    super.key,
    required this.content,
    required this.palette,
    required this.shape,
    required this.reading,
  });

  final CardContent content;
  final CardPalette palette;
  final CardShape shape;
  final VerseReading reading;

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
            padding: EdgeInsets.fromLTRB(24, reading.pad, 24, reading.pad),
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
                    child: VerseReference(
                      reference: content.reference,
                      translation: content.translation,
                      upper: true,
                      size: 9.3,
                      styleFor: (s) => SnippetFonts.monoText(
                        s,
                        bold: true,
                        color: palette.surfaceInk,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: reading.gap),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: AutoFitText(
                      content.text.toUpperCase(),
                      maxSize: reading.size,
                      minSize: reading.minSize,
                      styleFor: (s) => SnippetFonts.grotesk(
                        s,
                        weight: FontWeight.w800,
                        condensed: true,
                        color: palette.ink,
                        height: reading.height,
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
