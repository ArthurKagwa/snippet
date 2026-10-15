import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';

/// Stone panel with the wide elliptical top edge used across the app
/// (verse picker, style panel, sheets).
class ArchPanel extends StatelessWidget {
  const ArchPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 50, 24, 24),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  static const BorderRadius radius = BorderRadius.vertical(
    top: Radius.elliptical(180, 50),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: color ?? c.stone,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: c.ink),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
