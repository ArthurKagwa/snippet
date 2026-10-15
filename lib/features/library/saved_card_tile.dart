import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/quote_card.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/saved_card.dart';

/// Library grid tile: the saved card, its reference, and its look.
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onLongPress,
  });

  final SavedCard card;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = CardCatalog.byId(card.styleId);
    final variant = style.variant(card.variantId);
    return Semantics(
      button: true,
      label: '${card.reference}, ${style.name} ${variant.name}',
      hint: 'Long press to remove',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuoteCard(
                content: card.content,
                style: style,
                variant: variant,
                radius: 8,
              ),
              const SizedBox(height: 7),
              Text(
                card.reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SnippetFonts.serifText(15, color: c.white, height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                '${style.name} · ${variant.name}',
                style: SnippetFonts.body(8.7, color: c.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
