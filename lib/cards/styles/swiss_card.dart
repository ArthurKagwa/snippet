import 'package:flutter/widgets.dart';

import '../../core/theme/snippet_fonts.dart';
import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';

/// Swiss: flush-left grotesk, one colour bar, mono reference.
class SwissCard extends StatelessWidget {
  const SwissCard({
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
    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 72, height: 8, color: palette.accent),
            const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AutoFitText(
                  content.text,
                  maxSize: 30,
                  styleFor: (s) => SnippetFonts.grotesk(
                    s,
                    weight: FontWeight.w700,
                    color: palette.ink,
                    height: 0.98,
                    letterSpacing: -s * 0.034,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content.referenceLine,
              textScaler: TextScaler.noScaling,
              style: SnippetFonts.monoText(9.3, color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}
