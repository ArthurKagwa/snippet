import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';

/// Cobalt Arch: the app's own motif. A stone arch on colour, lime sun.
class CobaltArchCard extends StatelessWidget {
  const CobaltArchCard({
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
    const side = 28.0;
    const archWidth = CardShape.designWidth - side * 2;
    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(side, side, side, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(archWidth / 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: reading.gap),
                Expanded(
                  child: Center(
                    child: AutoFitText(
                      content.text,
                      maxSize: reading.size,
                      minSize: reading.minSize,
                      textAlign: TextAlign.center,
                      styleFor: (s) => SnippetFonts.serifText(
                        s,
                        color: palette.surfaceInk,
                        height: reading.height,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: reading.gap),
                VerseReference(
                  reference: content.reference,
                  upper: true,
                  size: 9.3,
                  textAlign: TextAlign.center,
                  styleFor: (s) => SnippetFonts.display(
                    s,
                    weight: FontWeight.w700,
                    color: palette.surfaceInk,
                    letterSpacing: s * 0.14,
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
