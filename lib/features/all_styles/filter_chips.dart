import 'package:flutter/material.dart';

import '../../cards/card_style_spec.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// All / Classic / Bold / Soft / Minimal. Null means All.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StyleTag? selected;
  final ValueChanged<StyleTag?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget chip(String label, StyleTag? tag) {
      final on = tag == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: on ? c.lime : c.surfaceDark,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onChanged(tag),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              child: Text(
                label,
                style: on
                    ? SnippetFonts.display(
                        10,
                        weight: FontWeight.w700,
                        color: c.ink,
                      )
                    : SnippetFonts.body(
                        10,
                        weight: FontWeight.w600,
                        color: c.white,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          chip('All', null),
          for (final t in StyleTag.values) chip(t.label, t),
        ],
      ),
    );
  }
}
