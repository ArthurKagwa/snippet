import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';

/// 40dp round header button, outlined in the translucent line color.
class CircleButton extends StatelessWidget {
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
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final Color? background;
  final Color? foreground;

  /// Pass transparent to drop the outline.
  final Color? borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? c.white;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: background ?? Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(color: borderColor ?? c.line, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: size * 0.45),
                child: child ?? Icon(icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
