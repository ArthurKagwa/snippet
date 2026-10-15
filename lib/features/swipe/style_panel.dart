import 'package:flutter/material.dart';

import '../../cards/card_palette.dart';
import '../../cards/card_style_spec.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/arch_panel.dart';
import '../../widgets/pill_button.dart';

/// Stone panel under the swipe card: style name, colour swatches, actions.
class StylePanel extends StatelessWidget {
  const StylePanel({
    super.key,
    required this.style,
    required this.variantIndex,
    required this.onVariant,
    required this.onSave,
    required this.onExport,
  });

  final CardStyleSpec style;
  final int variantIndex;
  final ValueChanged<int> onVariant;
  final VoidCallback onSave;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final variant = style.variants[variantIndex];
    return ArchPanel(
      padding: EdgeInsets.fromLTRB(
        24,
        46,
        24,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    style.name,
                    key: ValueKey(style.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.display(
                      26,
                      color: c.ink,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Text(
                style.collection,
                style: SnippetFonts.body(10, color: c.inkDim),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < style.variants.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _Swatch(
                  variant: style.variants[i],
                  outlined: style.id == 'riso',
                  selected: i == variantIndex,
                  onTap: () => onVariant(i),
                ),
              ],
              const Spacer(),
              Icon(Icons.swap_horiz_rounded, size: 14, color: c.inkDim),
              const SizedBox(width: 3),
              Text(
                variant.name,
                style: SnippetFonts.body(9.5, color: c.inkDim),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: PillButton(
                  key: const Key('save-card'),
                  label: 'Save',
                  icon: Icons.bookmark_border_rounded,
                  onPressed: onSave,
                  foreground: c.ink,
                  height: 52,
                  fontSize: 12.7,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 16,
                child: PillButton(
                  key: const Key('export-card'),
                  label: 'Export',
                  icon: Icons.download_rounded,
                  onPressed: onExport,
                  background: c.cobalt,
                  foreground: c.white,
                  height: 52,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.variant,
    required this.outlined,
    required this.selected,
    required this.onTap,
  });

  final CardVariant variant;
  final bool outlined;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: variant.name,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: variant.swatch,
            shape: BoxShape.circle,
            border: Border.all(
              color: outlined ? variant.palette.border : c.stone2,
              width: outlined ? 1.3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(color: c.cobalt, spreadRadius: 4),
                    BoxShadow(color: c.stone, spreadRadius: 2.3),
                  ]
                : const [],
          ),
        ),
      ),
    );
  }
}
