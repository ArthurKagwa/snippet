import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';

/// Vigil: illuminated-manuscript feel. Fleuron, italic Cormorant, inset rule.
class VigilCard extends StatelessWidget {
  const VigilCard({
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
    final vertical = shape == CardShape.feed ? 32.0 : 44.0;
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
                const SizedBox(height: 18),
                Flexible(
                  child: AutoFitText(
                    content.text,
                    maxSize: 25,
                    textAlign: TextAlign.center,
                    styleFor: (s) => SnippetFonts.cormorantText(
                      s,
                      italic: true,
                      weight: FontWeight.w400,
                      color: palette.ink,
                      height: 1.18,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  content.referenceLine,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: SnippetFonts.monoText(
                    8.5,
                    color: palette.accent,
                    letterSpacing: 1.7,
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
