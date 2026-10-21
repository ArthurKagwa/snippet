import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/services.dart';

/// Home refreshes this greeting on resume and at local minute boundaries.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  static String forTime(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Services.of(context).auth;
    return StreamBuilder(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user == null || user.isAnonymous
            ? null
            : user.displayName?.trim();
        final greeting = forTime(Services.of(context).now());
        return Text(
          name == null || name.isEmpty ? greeting : '$greeting, $name',
          key: const Key('home-greeting'),
          style: SnippetFonts.display(24, color: context.colors.white),
        );
      },
    );
  }
}
