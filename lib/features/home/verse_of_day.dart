import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/card_content.dart';
import '../../cards/quote_card.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/bible_models.dart';
import '../../widgets/pill_button.dart';

/// "TODAY": a Dawn card of the daily verse with a jump into swiping.
class VerseOfDay extends StatelessWidget {
  const VerseOfDay({
    super.key,
    required this.passage,
    required this.pullQuote,
    required this.onSwipe,
  });

  final Passage passage;

  /// Short line under the reference (usually the last verse).
  final String pullQuote;
  final VoidCallback onSwipe;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dawn = CardCatalog.byId('dawn');
    return Semantics(
      label: 'Verse of the day',
      container: true,
      child: Row(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QuoteCard(
              radius: 10,
              style: dawn,
              variant: dawn.variants.first,
              content: CardContent(
                text: passage.text,
                reference: passage.reference,
                translation: '',
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY',
                  style: SnippetFonts.display(
                    9,
                    weight: FontWeight.w700,
                    color: c.lime,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  passage.reference,
                  style: SnippetFonts.serifText(
                    21,
                    color: c.white,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '“$pullQuote”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: SnippetFonts.body(12.5, color: c.mist, height: 1.35),
                ),
                const SizedBox(height: 10),
                PillButton(
                  key: const Key('votd-swipe'),
                  label: 'Preview',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onSwipe,
                  background: c.lime,
                  foreground: c.ink,
                  height: 40,
                  fontSize: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
