import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// 44dp row with a hairline underneath. Tappable when [onTap] is set.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.lineDark, width: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SnippetFonts.body(13.3, color: c.white)),
          ),
          if (value != null)
            Text(value!, style: SnippetFonts.body(11.5, color: c.mist)),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, color: c.mist, size: 18),
          ],
          ?trailing,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
