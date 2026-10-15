import 'package:flutter/material.dart';

import '../core/theme/snippet_fonts.dart';

/// Segmented pill (KJV / WEB). Selected segment is filled.
class PillToggle<T> extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    required this.track,
    required this.selectedFill,
    required this.selectedText,
    required this.text,
    this.segmentWidth = 44,
    this.height = 32,
    this.semanticLabel,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final Color track;
  final Color selectedFill;
  final Color selectedText;
  final Color text;
  final double segmentWidth;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: ShapeDecoration(color: track, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              Semantics(
                button: true,
                selected: o == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: segmentWidth,
                    height: height,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: o == selected ? selectedFill : track.withAlpha(0),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      labelOf(o),
                      style: SnippetFonts.display(
                        height * 0.31,
                        weight: FontWeight.w700,
                        color: o == selected ? selectedText : text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
