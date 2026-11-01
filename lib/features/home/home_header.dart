import 'package:flutter/material.dart';

import '../../services/services.dart';
import '../../widgets/cobalt_header.dart';
import '../../widgets/profile_button.dart';
import '../../widgets/snippet_wordmark.dart';
import '../profile/profile_screen.dart';
import '../shell/shell_controller.dart';
import 'announcement_banner.dart';

/// Brand, account access, and the dismissible announcement on Home.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.announcement});

  final String? announcement;

  Future<void> _openProfile(BuildContext context) {
    final shell = ShellScope.read(context);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(onShowSaved: () => shell.select(ShellTab.saved)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Services.of(context).settings;
    return Column(
      children: [
        CobaltHeader(
          child: Row(
            children: [
              const SnippetWordmark(),
              const Spacer(),
              ProfileButton(onPressed: () => _openProfile(context)),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => AnnouncementBanner(
            message: announcement != settings.dismissedAnnouncement
                ? announcement
                : null,
            onDismiss: () => settings.dismissedAnnouncement = announcement,
          ),
        ),
      ],
    );
  }
}
