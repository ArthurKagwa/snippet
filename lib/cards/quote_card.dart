import 'package:flutter/material.dart';

import '../core/theme/snippet_fonts.dart';
import 'card_content.dart';
import 'card_palette.dart';
import 'card_shape.dart';
import 'card_style_spec.dart';

/// Hero tag shared by every on-screen copy of one style + colourway, so a
/// thumbnail can fly into the full-size card.
String cardHeroTag(CardStyleSpec style, CardVariant variant) =>
    'card-${style.id}-${variant.id}';

/// A card at any size: composed at [CardShape.designWidth] and scaled, so
/// thumbnails, the swipe preview and the export all match.
///
/// Wrap in a RepaintBoundary to export.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.content,
    required this.style,
    required this.variant,
    this.shape = CardShape.portrait,
    this.showMark = false,
    this.radius = 0,
  });

  final CardContent content;
  final CardStyleSpec style;
  final CardVariant variant;
  final CardShape shape;
  final bool showMark;

  /// Corner radius in design units (scaled with the card).
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = variant.palette;
    return AspectRatio(
      aspectRatio: shape.aspectRatio,
      child: FittedBox(
        child: SizedBox(
          width: CardShape.designWidth,
          height: shape.designHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                style.builder(content, palette, shape),
                if (showMark)
                  Positioned(
                    right: 10,
                    bottom: 7,
                    child: Text(
                      'snippet',
                      textScaler: TextScaler.noScaling,
                      style: SnippetFonts.display(
                        8,
                        color: palette.ink.withValues(alpha: 0.55),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
