import 'package:flutter/material.dart';

import '../../cards/snippet_mark.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/pill_button.dart';

/// Full-screen demand to update. There is no dismiss control.
///
/// System back does not leave this screen. The only action opens Google Play.
class RequiredUpdateScreen extends StatelessWidget {
  const RequiredUpdateScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onUpdate,
    this.storeFailed = false,
  });

  final String title;
  final String message;
  final Future<void> Function() onUpdate;
  final bool storeFailed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('required-update'),
        backgroundColor: c.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SnippetMark(color: c.white, size: 18),
                const Spacer(),
                Text(
                  title,
                  style: SnippetFonts.display(
                    36,
                    color: c.white,
                    letterSpacing: -1.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: SnippetFonts.body(16, color: c.mist, height: 1.45),
                ),
                const Spacer(),
                if (storeFailed) ...[
                  Text(
                    "Google Play didn't open. Try again.",
                    key: const Key('required-update-error'),
                    style: SnippetFonts.body(14, color: c.danger, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    key: const Key('required-update-button'),
                    label: 'Update',
                    foreground: c.ink,
                    background: c.lime,
                    onPressed: onUpdate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
