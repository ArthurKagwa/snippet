import 'package:flutter/material.dart';

import '../../cards/card_content.dart';
import '../../cards/card_palette.dart';
import '../../cards/card_style_spec.dart';
import '../../cards/quote_card.dart';
import '../../cards/verse_scale.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../core/theme/snippet_motion.dart';
import '../../widgets/press_scale.dart';

/// Grid tile: a card thumbnail with the style name and colour count.
class StyleTile extends StatelessWidget {
  const StyleTile({
    super.key,
    required this.style,
    required this.variant,
    required this.content,
    required this.selected,
    required this.onTap,
    this.hero = false,
  });

  final CardStyleSpec style;
  final CardVariant variant;
  final CardContent content;
  final bool selected;
  final VoidCallback onTap;

  /// Flies into the swipe card when this tile is picked.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: style.name,
      child: PressScale(
        onTap: onTap,
        scale: 0.97,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shape = VerseScales.previewShape(style, content);
                  final fitted = _fit(constraints.biggest, shape.aspectRatio);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: HeroMode(
                      enabled: hero && !SnippetMotion.reduce(context),
                      child: Hero(
                        tag: cardHeroTag(style, variant),
                        child: Container(
                          width: fitted.width,
                          height: fitted.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: selected
                                ? [
                                    BoxShadow(color: c.lime, spreadRadius: 4.7),
                                    BoxShadow(
                                      color: c.black,
                                      spreadRadius: 2.7,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: QuoteCard(
                            content: content,
                            style: style,
                            variant: variant,
                            shape: shape,
                            radius: 8,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    style.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.display(13, color: c.white),
                  ),
                ),
                Text(
                  '${style.variants.length} colours',
                  style: SnippetFonts.body(9, color: c.mist),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The largest rectangle of [aspect] (width / height) that fits in [box].
Size _fit(Size box, double aspect) {
  var width = box.width;
  var height = width / aspect;
  if (height > box.height && box.height.isFinite) {
    height = box.height;
    width = height * aspect;
  }
  return Size(width, height);
}
