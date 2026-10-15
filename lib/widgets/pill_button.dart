import 'package:flutter/material.dart';

import '../core/theme/snippet_fonts.dart';
import 'async_tap.dart';

/// Full-round button. Filled when [background] is set, otherwise outlined
/// in [foreground].
///
/// Shrinks while pressed. When [onPressed] returns a Future (or [busy] is
/// set) it shows a spinner and ignores taps until the work is done; a null
/// [onPressed] dims it as disabled.
class PillButton extends StatefulWidget {
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
    this.busy = false,
  });

  final String label;
  final TapAction? onPressed;
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

  /// Shows the spinner for work started elsewhere (e.g. a parent's state).
  final bool busy;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> with AsyncTap {
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final busy = w.busy || running;
    final enabled = w.onPressed != null && !busy;
    final hasBorder = w.outlined ?? w.background == null;
    final style =
        w.labelStyle ??
        SnippetFonts.display(w.fontSize, weight: FontWeight.w700);
    final iconSize = w.fontSize * 1.25;

    Widget? lead;
    if (busy) {
      lead = SizedBox.square(
        dimension: iconSize,
        child: CircularProgressIndicator(strokeWidth: 2, color: w.foreground),
      );
    } else if (w.leading != null) {
      lead = w.leading;
    } else if (w.icon != null) {
      lead = Icon(w.icon, size: iconSize, color: w.foreground);
    }

    return Semantics(
      liveRegion: busy,
      child: AnimatedOpacity(
        opacity: w.onPressed == null && !busy ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedScale(
          scale: pressed && enabled ? 0.96 : 1,
          duration: Duration(milliseconds: pressed ? 90 : 160),
          curve: Curves.easeOut,
          child: SizedBox(
            height: w.height,
            child: Material(
              color: w.background ?? Colors.transparent,
              shape: StadiumBorder(
                side: hasBorder
                    ? BorderSide(color: w.foreground, width: w.borderWidth)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => runTap(w.onPressed) : null,
                onHighlightChanged: setPressed,
                splashColor: w.foreground.withValues(alpha: 0.2),
                highlightColor: w.foreground.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lead != null) ...[
                        lead,
                        SizedBox(width: w.leading != null && !busy ? 9 : 6),
                      ],
                      Flexible(
                        child: Text(
                          w.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.copyWith(color: w.foreground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
