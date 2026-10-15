import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Outlined pill showing the current book; opens the book picker.
class BookButton extends StatelessWidget {
  const BookButton({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      key: const Key('book-button'),
      color: c.stone.withAlpha(0),
      shape: StadiumBorder(side: BorderSide(color: c.ink, width: 1.4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Book',
                  style: SnippetFonts.body(
                    13,
                    weight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.serifText(24, color: c.ink, height: 1),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: c.ink, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
