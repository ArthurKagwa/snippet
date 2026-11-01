import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';
import 'arch_panel.dart';

/// Modal bottom sheet drawn as an [ArchPanel] over the scrim.
Future<T?> showArchSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(24, 48, 24, 16),
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.stone.withAlpha(0),
    barrierColor: c.scrim,
    elevation: 0,
    // The keyboard inset goes inside the panel so it grows above the keys.
    builder: (ctx) => ArchPanel(
      padding: padding.add(
        EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(child: builder(ctx)),
      ),
    ),
  );
}
