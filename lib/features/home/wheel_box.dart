import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Stone box with a small label above a [NumberWheel].
class WheelBox extends StatelessWidget {
  const WheelBox({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        color: c.stone2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: SnippetFonts.body(10, color: c.inkDim)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}
