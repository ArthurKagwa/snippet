import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../widgets/icons/google_logo.dart';

/// Avatar, name, email and how the user signed in.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initials = user.initials;
    final name = user.isAnonymous
        ? 'On this phone'
        : (user.displayName ?? 'Signed in');
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.lime, shape: BoxShape.circle),
          child: initials.isEmpty
              ? Icon(Icons.person_rounded, color: c.ink, size: 30)
              : Text(initials, style: SnippetFonts.display(24, color: c.ink)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SnippetFonts.display(
                  20,
                  color: c.white,
                  letterSpacing: -0.7,
                  height: 1,
                ),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SnippetFonts.body(10, color: c.mist),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!user.isAnonymous) ...[
                    const GoogleLogo(size: 11),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    user.isAnonymous
                        ? 'Cards stay on this device'
                        : 'Signed in with Google',
                    style: SnippetFonts.body(8.7, color: c.mist),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
