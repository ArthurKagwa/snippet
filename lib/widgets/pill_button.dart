import 'package:flutter/material.dart';

import '../core/theme/snippet_fonts.dart';

/// Full-round button. Filled when [background] is set, otherwise outlined
/// in [foreground].
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.foreground,
    this.background,
    this.icon,
    this.leading,
    this.height = 52,
    this.fontSize = 14,
    this.borderWidth = 1.4,
    this.outlined,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color foreground;
  final Color? background;
  final IconData? icon;

  /// Custom leading widget (e.g. the Google logo); wins over [icon].
  final Widget? leading;
  final double height;
  final double fontSize;
  final double borderWidth;

  /// Defaults to true when there is no [background].
  final bool? outlined;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final hasBorder = outlined ?? background == null;
    final style =
        labelStyle ?? SnippetFonts.display(fontSize, weight: FontWeight.w700);
    return SizedBox(
      height: height,
      child: Material(
        color: background ?? Colors.transparent,
        shape: StadiumBorder(
          side: hasBorder
              ? BorderSide(color: foreground, width: borderWidth)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 9),
                ] else if (icon != null) ...[
                  Icon(icon, size: fontSize * 1.25, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
