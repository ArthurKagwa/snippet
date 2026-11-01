import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';

/// Swiss: flush-left grotesk, one colour bar, mono reference.
class SwissCard extends StatelessWidget {
  const SwissCard({
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
    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: reading.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 72, height: 8, color: palette.accent),
            SizedBox(height: reading.gap),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AutoFitText(
                  content.text,
                  maxSize: reading.size,
                  minSize: reading.minSize,
                  styleFor: (s) => SnippetFonts.grotesk(
                    s,
                    weight: FontWeight.w700,
                    color: palette.ink,
                    height: reading.height,
                    letterSpacing: -s * 0.034,
                  ),
                ),
              ),
            ),
            SizedBox(height: reading.gap),
            VerseReference(
              reference: content.reference,
              translation: content.translation,
              upper: true,
              size: 9.3,
              styleFor: (s) => SnippetFonts.monoText(s, color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}
