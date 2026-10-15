import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/snippet_switch.dart';

/// A labelled switch in the export sheet, with an optional detail line.
class ExportToggleRow extends StatelessWidget {
  const ExportToggleRow({
    super.key,
    required this.label,
    this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: SnippetFonts.body(12, color: c.ink)),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!, style: SnippetFonts.body(8.7, color: c.inkDim)),
              ],
            ],
          ),
        ),
        SnippetSwitch(
          semanticLabel: label,
          value: value,
          onChanged: onChanged,
          onTrack: c.cobalt,
          onThumb: c.white,
          offTrack: c.stone2,
          offThumb: c.white,
        ),
      ],
    );
  }
}
