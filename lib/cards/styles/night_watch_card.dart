import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';

/// Night Watch: deep gradient, short rule, upright Instrument Serif.
class NightWatchCard extends StatelessWidget {
  const NightWatchCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 2, color: palette.accent),
            const SizedBox(height: 20),
            Flexible(
              child: AutoFitText(
                content.text,
                maxSize: 29,
                styleFor: (s) => SnippetFonts.serifText(
                  s,
                  italic: false,
                  color: palette.ink,
                  height: 1.06,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content.referenceLine,
              textScaler: TextScaler.noScaling,
              style: SnippetFonts.monoText(
                9.3,
                color: palette.accent,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
