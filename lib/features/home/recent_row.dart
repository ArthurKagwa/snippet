import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/app_settings.dart';

/// Horizontally scrolling chips of recently opened verses.
class RecentRow extends StatelessWidget {
  const RecentRow({super.key, required this.recent, required this.onTap});

  final List<RecentVerse> recent;
  final ValueChanged<RecentVerse> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text('Recent', style: SnippetFonts.body(9.5, color: c.inkDim)),
          for (final r in recent) ...[
            const SizedBox(width: 6),
            Material(
              color: c.stone2,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onTap(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Text(
                    r.label,
                    style: SnippetFonts.body(
                      9.5,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
