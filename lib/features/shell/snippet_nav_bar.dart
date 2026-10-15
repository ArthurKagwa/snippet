import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/icons/arch_icon.dart';
import 'shell_controller.dart';

/// Home / Styles / Saved. The current tab sits in a lime pill.
class SnippetNavBar extends StatelessWidget {
  const SnippetNavBar({super.key, required this.tab, required this.onTab});

  final ShellTab tab;
  final ValueChanged<ShellTab> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(ShellTab t, String label, Widget icon) {
      final on = t == tab;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: InkResponse(
            key: Key('nav-${t.name}'),
            onTap: () => onTab(t),
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 56,
                    height: 30,
                    decoration: ShapeDecoration(
                      color: on ? c.lime : c.black.withAlpha(0),
                      shape: const StadiumBorder(),
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: on ? c.ink : c.mist, size: 21),
                      child: Center(child: icon),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: SnippetFonts.display(
                      10.5,
                      weight: FontWeight.w700,
                      color: on ? c.white : c.mist,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.black,
        border: Border(top: BorderSide(color: c.lineDark, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              item(ShellTab.home, 'Home', const Icon(Icons.home_rounded)),
              item(ShellTab.styles, 'Styles', const ArchIcon()),
              item(ShellTab.saved, 'Saved', const Icon(Icons.bookmark_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}
