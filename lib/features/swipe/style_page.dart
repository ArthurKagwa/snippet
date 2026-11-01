import 'package:flutter/material.dart';

import '../../cards/card_content.dart';
import '../../cards/card_shape.dart';
import '../../cards/card_style_spec.dart';
import '../../cards/quote_card.dart';
import '../../core/theme/snippet_colors.dart';
import 'swipe_page_physics.dart';

/// One style in the vertical stack: its colourways side by side in a
/// horizontal PageView, with the next style peeking out underneath.
class StylePage extends StatelessWidget {
  const StylePage({
    super.key,
    required this.style,
    required this.content,
    required this.controller,
    required this.cardSize,
    required this.onVariantChanged,
    this.shape = CardShape.portrait,
    this.nextStyle,
  });

  final CardStyleSpec style;
  final CardStyleSpec? nextStyle;
  final CardContent content;
  final PageController controller;
  final Size cardSize;
  final ValueChanged<int> onVariantChanged;
  final CardShape shape;

  /// How far the next style's edge shows under the card.
  static const double peekDepth = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: cardSize.height + peekDepth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (nextStyle != null)
              Positioned(
                bottom: 0,
                width: cardSize.width * 0.9,
                height: peekDepth * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: nextStyle!.variants.first.palette.background,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: cardSize.height,
              child: PageView.builder(
                key: PageStorageKey('variants-${style.id}'),
                controller: controller,
                pageSnapping: false,
                physics: SwipePagePhysics(
                  parent: ScrollConfiguration.of(context)
                      .getScrollPhysics(context),
                ),
                itemCount: style.variants.length,
                onPageChanged: onVariantChanged,
                itemBuilder: (context, i) => Center(
                  // Lands the tile picked in All styles.
                  child: Hero(
                    tag: cardHeroTag(style, style.variants[i]),
                    child: Container(
                      width: cardSize.width,
                      height: cardSize.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: c.shadow,
                            blurRadius: 30,
                            offset: const Offset(0, 13),
                          ),
                        ],
                      ),
                      child: QuoteCard(
                        key: Key('card-${style.id}-${style.variants[i].id}'),
                        content: content,
                        style: style,
                        variant: style.variants[i],
                        shape: shape,
                        radius: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
