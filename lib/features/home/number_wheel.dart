import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Vertical wheel of numbers with the selection in a cobalt pill.
class NumberWheel extends StatefulWidget {
  const NumberWheel({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.width = 64,
  });

  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final String semanticLabel;
  final double width;

  static const double itemExtent = 30;
  static const double height = itemExtent * 3;

  @override
  State<NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<NumberWheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.value - widget.min);

  @override
  void didUpdateWidget(NumberWheel old) {
    super.didUpdateWidget(old);
    final target = widget.value - widget.min;
    if (_controller.hasClients && _controller.selectedItem != target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(widget.value - widget.min);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = widget.max - widget.min + 1;
    return Semantics(
      label: widget.semanticLabel,
      value: '${widget.value}',
      increasedValue: widget.value < widget.max ? '${widget.value + 1}' : null,
      decreasedValue: widget.value > widget.min ? '${widget.value - 1}' : null,
      onIncrease: widget.value < widget.max
          ? () => widget.onChanged(widget.value + 1)
          : null,
      onDecrease: widget.value > widget.min
          ? () => widget.onChanged(widget.value - 1)
          : null,
      child: SizedBox(
        width: widget.width,
        height: NumberWheel.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: NumberWheel.itemExtent + 2,
              decoration: ShapeDecoration(
                color: c.cobalt,
                shape: const StadiumBorder(),
              ),
            ),
            ExcludeSemantics(
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: NumberWheel.itemExtent,
                diameterRatio: 2.4,
                perspective: 0.002,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  final value = widget.min + i;
                  // Programmatic jumps already reflect the parent's selection.
                  // Sending them back would reset the selected verse range.
                  if (value != widget.value) widget.onChanged(value);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (context, i) {
                    final n = widget.min + i;
                    final selected = n == widget.value;
                    return Center(
                      child: Text(
                        '$n',
                        style: SnippetFonts.display(
                          selected ? 24 : 16,
                          weight: selected ? FontWeight.w800 : FontWeight.w700,
                          color: selected
                              ? c.white
                              : c.ink.withValues(alpha: 0.7),
                          height: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
