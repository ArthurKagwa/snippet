import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';

/// Night Watch: deep gradient, short rule, upright Instrument Serif.
class NightWatchCard extends StatelessWidget {
  const NightWatchCard({
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
        gradient: LinearGradient(
          begin: const Alignment(-0.09, -1),
          end: const Alignment(0.09, 1),
          colors: [
            palette.background,
            palette.backgroundEnd ?? palette.background,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: reading.pad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 2, color: palette.accent),
            SizedBox(height: reading.gap),
            Flexible(
              child: AutoFitText(
                content.text,
                maxSize: reading.size,
                minSize: reading.minSize,
                styleFor: (s) => SnippetFonts.serifText(
                  s,
                  italic: false,
                  color: palette.ink,
                  height: reading.height,
                ),
              ),
            ),
            SizedBox(height: reading.gap),
            VerseReference(
              reference: content.reference,
              translation: content.translation,
              upper: true,
              size: 9.3,
              styleFor: (s) => SnippetFonts.monoText(
                s,
                color: palette.accent,
                letterSpacing: s * 0.14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
