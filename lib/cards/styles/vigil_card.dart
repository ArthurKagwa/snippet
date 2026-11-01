import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../verse_reference.dart';
import '../verse_scale.dart';

/// Vigil: illuminated-manuscript feel. Fleuron, italic Cormorant, inset rule.
class VigilCard extends StatelessWidget {
  const VigilCard({
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
    final vertical = shape == CardShape.feed ? reading.pad * 0.72 : reading.pad;
    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: palette.accentDim, width: 1),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: vertical),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '❧',
                  textScaler: TextScaler.noScaling,
                  style: SnippetFonts.cormorantText(24, color: palette.accent),
                ),
                SizedBox(height: reading.gap),
                Flexible(
                  child: AutoFitText(
                    content.text,
                    maxSize: reading.size,
                    minSize: reading.minSize,
                    textAlign: TextAlign.center,
                    styleFor: (s) => SnippetFonts.cormorantText(
                      s,
                      italic: true,
                      weight: FontWeight.w400,
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
                  size: 8.5,
                  textAlign: TextAlign.center,
                  styleFor: (s) => SnippetFonts.monoText(
                    s,
                    color: palette.accent,
                    letterSpacing: s * 0.2,
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
