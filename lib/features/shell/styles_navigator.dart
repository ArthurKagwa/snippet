import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../swipe/swipe_screen.dart';
import 'shell_controller.dart';

/// Styles routes stay inside the shell so its bottom navigation stays visible.
class StylesNavigator extends StatelessWidget {
  const StylesNavigator({
    super.key,
    required this.shell,
    required this.navigatorKey,
  });

  final ShellController shell;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: shell,
          builder: (context, _) {
            final passage = shell.passage;
            if (passage == null) {
              return Center(
                child: CircularProgressIndicator(color: context.colors.lime),
              );
            }
            return SwipeScreen(
              key: ValueKey(shell.openCount),
              passage: passage,
              initialStyleId: shell.styleId,
              initialVariantId: shell.variantId,
            );
          },
        ),
      ),
    );
  }
}
