import 'package:flutter/material.dart';

import '../../cards/card_content.dart';
import '../../cards/card_palette.dart';
import '../../cards/card_shape.dart';
import '../../cards/card_style_spec.dart';
import '../../cards/quote_card.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/press_scale.dart';

/// A live mini card in one shape. The selected one doubles as the export
/// source: its [boundaryKey] is captured at full resolution.
class ShapeOption extends StatelessWidget {
  const ShapeOption({
    super.key,
    required this.shape,
    required this.content,
    required this.style,
    required this.variant,
    required this.showMark,
    required this.selected,
    required this.onTap,
    required this.width,
    this.boundaryKey,
  });

  final CardShape shape;
  final CardContent content;
  final CardStyleSpec style;
  final CardVariant variant;
  final bool showMark;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${shape.label} ${shape.ratioLabel}',
      child: PressScale(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: width,
              decoration: BoxDecoration(
                boxShadow: selected
                    ? [
                        BoxShadow(color: c.cobalt, spreadRadius: 4),
                        BoxShadow(color: c.stone, spreadRadius: 2.3),
                      ]
                    : const [],
              ),
              child: RepaintBoundary(
                key: boundaryKey,
                child: QuoteCard(
                  content: content,
                  style: style,
                  variant: variant,
                  shape: shape,
                  showMark: showMark,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              shape.label,
              style: SnippetFonts.display(
                12,
                weight: selected ? FontWeight.w800 : FontWeight.w700,
                color: c.ink,
              ),
            ),
            Text(
              shape.ratioLabel,
              style: SnippetFonts.body(8.7, color: c.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}
