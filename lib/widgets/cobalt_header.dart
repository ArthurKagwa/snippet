import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';

/// The cobalt band at the top of every screen. Sits under the status bar
/// and lays its children out in a 40dp row.
class CobaltHeader extends StatelessWidget {
  const CobaltHeader({super.key, required this.child, this.extraBottom = 0});

  final Widget child;

  /// Extra cobalt below the row (Swipe lets the card overlap it).
  final double extraBottom;

  static const double rowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: context.colors.cobalt,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12 + extraBottom),
        child: SizedBox(height: rowHeight, child: child),
      ),
    );
  }
}
