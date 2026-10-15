import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';
import '../core/theme/snippet_fonts.dart';

/// "snippet" in Syne ExtraBold with the lime full stop.
class SnippetWordmark extends StatelessWidget {
  const SnippetWordmark({super.key, this.size = 25});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      header: true,
      label: 'Snippet',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'snippet',
              style: SnippetFonts.display(
                size,
                color: c.white,
                letterSpacing: -size * 0.04,
                height: 1,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.12),
              child: Container(
                width: size * 0.29,
                height: size * 0.29,
                decoration: BoxDecoration(
                  color: c.lime,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
