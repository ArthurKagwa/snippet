import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Lime instruction under the card; switches while swiping sideways.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key, required this.sideways, required this.isLast});

  final bool sideways;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, text) = sideways
        ? (Icons.swap_horiz_rounded, 'Same style, new colours')
        : isLast
        ? (Icons.arrow_downward_rounded, 'That’s every style. Swipe back down')
        : (Icons.arrow_upward_rounded, 'Swipe up for the next style');
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Row(
          key: ValueKey(text),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c.lime, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: SnippetFonts.display(
                9.5,
                weight: FontWeight.w700,
                color: c.lime,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
