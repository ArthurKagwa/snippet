import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';
import 'async_tap.dart';

/// 40dp round header button, outlined in the translucent line color.
///
/// Shrinks while pressed. When [onPressed] returns a Future (e.g. a pushed
/// route), further taps are ignored until it completes, so a double tap
/// cannot open the same screen twice.
class CircleButton extends StatefulWidget {
  const CircleButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
    this.background,
    this.foreground,
    this.borderColor,
    this.size = 40,
  });

  final String tooltip;
  final TapAction? onPressed;
  final IconData? icon;
  final Widget? child;
  final Color? background;
  final Color? foreground;

  /// Pass transparent to drop the outline.
  final Color? borderColor;
  final double size;

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> with AsyncTap {
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final c = context.colors;
    final fg = w.foreground ?? c.white;
    final enabled = w.onPressed != null && !running;
    return Tooltip(
      message: w.tooltip,
      child: AnimatedScale(
        scale: pressed && enabled ? 0.9 : 1,
        duration: Duration(milliseconds: pressed ? 90 : 160),
        curve: Curves.easeOut,
        child: SizedBox.square(
          dimension: w.size,
          child: Material(
            color: w.background ?? Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: w.borderColor ?? c.line, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => runTap(w.onPressed) : null,
              onHighlightChanged: setPressed,
              splashColor: fg.withValues(alpha: 0.2),
              highlightColor: fg.withValues(alpha: 0.12),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: w.size * 0.45),
                  child: w.child ?? Icon(w.icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
