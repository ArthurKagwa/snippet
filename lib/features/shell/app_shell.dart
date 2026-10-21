import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../library/library_screen.dart';
import 'shell_controller.dart';
import 'snippet_nav_bar.dart';
import 'styles_navigator.dart';

/// The three primary destinations behind the bottom nav. Tabs keep their
/// state while hidden; Profile, All styles and sheets open on top.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ShellController _shell = ShellController();
  final _stylesNavigator = GlobalKey<NavigatorState>();
  ShellTab _lastTab = ShellTab.home;

  @override
  void initState() {
    super.initState();
    _shell.addListener(_onShell);
  }

  void _onShell() {
    if (_lastTab == ShellTab.styles && _shell.tab != ShellTab.styles) {
      _stylesNavigator.currentState?.popUntil((route) => route.isFirst);
    }
    _lastTab = _shell.tab;
  }

  void _selectTab(ShellTab tab) {
    if (tab != ShellTab.styles) {
      _shell.select(tab);
    } else {
      _shell.openAllStyles();
    }
  }

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
            if (didPop) return;
            final navigator = _stylesNavigator.currentState;
            if (_shell.tab == ShellTab.styles &&
                navigator != null &&
                navigator.canPop()) {
              navigator.pop();
            } else {
              _selectTab(ShellTab.home);
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _shell.tab.index,
              children: [
                const HomeScreen(),
                StylesNavigator(shell: _shell, navigatorKey: _stylesNavigator),
                const LibraryScreen(),
              ],
            ),
            bottomNavigationBar: SnippetNavBar(
              tab: _shell.tab,
              onTab: _selectTab,
            ),
          ),
        ),
      ),
    );
  }
}
