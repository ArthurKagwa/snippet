import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/pill_button.dart';
import '../auth/sign_in_sheet.dart';

class LibraryVerificationNotice extends StatelessWidget {
  const LibraryVerificationNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verify your email to finish setting up your account '
              'and use your library.',
              textAlign: TextAlign.center,
              style: SnippetFonts.body(14, color: c.mist, height: 1.4),
            ),
            const SizedBox(height: 16),
            PillButton(
              key: const Key('library-verify-email'),
              label: 'Verify email',
              onPressed: () async {
                await ensureSignedIn(context);
              },
              background: c.lime,
              foreground: c.ink,
            ),
          ],
        ),
      ),
    );
  }
}
