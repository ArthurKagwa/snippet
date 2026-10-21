import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/bible_models.dart';

/// The daily reference and local date; the verse text lives in the picker.
class VerseOfDay extends StatelessWidget {
  const VerseOfDay({
    super.key,
    required this.passage,
    required this.day,
    required this.onSelect,
  });

  final Passage passage;
  final DateTime day;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Verse of the day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY',
                style: SnippetFonts.display(
                  10,
                  weight: FontWeight.w700,
                  color: c.lime,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextButton(
                  key: const Key('today-verse'),
                  onPressed: onSelect,
                  child: Text(
                    passage.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.serifText(21, color: c.white),
                  ),
                ),
              ),
            ],
          ),
          Text(
            MaterialLocalizations.of(context).formatFullDate(day),
            key: const Key('today-date'),
            style: SnippetFonts.body(12, color: c.mist),
          ),
        ],
      ),
    );
  }
}
