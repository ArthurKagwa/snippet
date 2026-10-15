import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Lime small-caps section label.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: SnippetFonts.display(
              8,
              weight: FontWeight.w700,
              color: c.lime,
              letterSpacing: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 2),
        ...children,
      ],
    );
  }
}
