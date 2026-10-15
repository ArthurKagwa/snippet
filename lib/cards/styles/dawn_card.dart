import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';

/// Dawn: warm gradient, big hanging quote mark, Cormorant upright.
class DawnCard extends StatelessWidget {
  const DawnCard({
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
    final top = shape == CardShape.feed ? 34.0 : 48.0;
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
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AutoFitText(
                  content.text,
                  maxSize: 24,
                  textAlign: TextAlign.center,
                  styleFor: (s) => SnippetFonts.cormorantText(
                    s,
                    color: palette.ink,
                    height: 1.15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content.referenceLine,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: SnippetFonts.monoText(
                8.5,
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
