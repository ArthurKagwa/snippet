import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../swipe/swipe_screen.dart';
import 'shell_controller.dart';
import 'snippet_nav_bar.dart';

/// The three primary destinations behind the bottom nav. Tabs keep their
/// state while hidden; Profile, All styles and sheets open on top.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ShellController _shell = ShellController();

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      controller: _shell,
      child: ListenableBuilder(
        listenable: _shell,
        builder: (context, _) => PopScope(
          // System back on Styles/Saved returns Home instead of exiting.
          canPop: _shell.tab == ShellTab.home,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _shell.select(ShellTab.home);
          },
          child: Scaffold(
            body: IndexedStack(
              index: _shell.tab.index,
              children: [
                const HomeScreen(),
                _stylesTab(context),
                const LibraryScreen(),
              ],
            ),
            bottomNavigationBar: SnippetNavBar(
              tab: _shell.tab,
              onTab: (t) => t == ShellTab.styles
                  ? _shell.openAllStyles()
                  : _shell.select(t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stylesTab(BuildContext context) {
    final passage = _shell.passage;
    if (passage == null) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.lime),
      );
    }
    return SwipeScreen(
      // A saved card reopens at its own look; a new verse keeps the style.
      key: ValueKey(_shell.openCount),
      passage: passage,
      initialStyleId: _shell.styleId,
      initialVariantId: _shell.variantId,
    );
  }
}
