import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';

/// Dawn: warm gradient, big hanging quote mark, Cormorant upright.
class DawnCard extends StatelessWidget {
  const DawnCard({
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
    final top = shape == CardShape.feed ? reading.pad * 0.7 : reading.pad;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.18, -1),
          end: const Alignment(0.18, 1),
          colors: [
            palette.background,
            palette.backgroundEnd ?? palette.background,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, top, 32, 28),
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: OverflowBox(
                maxHeight: 80,
                alignment: Alignment.topCenter,
                child: Text(
                  '“',
                  textScaler: TextScaler.noScaling,
                  style: SnippetFonts.serifText(
                    66,
                    italic: false,
                    color: palette.accent,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: reading.gap * 0.7),
            Expanded(
              child: Center(
                child: AutoFitText(
                  content.text,
                  maxSize: reading.size,
                  minSize: reading.minSize,
                  textAlign: TextAlign.center,
                  styleFor: (s) => SnippetFonts.cormorantText(
                    s,
                    color: palette.ink,
                    height: reading.height,
                  ),
                ),
              ),
            ),
            SizedBox(height: reading.gap),
            VerseReference(
              reference: content.reference,
              translation: content.translation,
              upper: true,
              size: 8.5,
              textAlign: TextAlign.center,
              styleFor: (s) => SnippetFonts.monoText(
                s,
                color: palette.accent,
                letterSpacing: s * 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
