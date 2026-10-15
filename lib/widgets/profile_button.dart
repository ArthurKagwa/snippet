import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';
import '../core/theme/snippet_fonts.dart';
import '../services/auth_service.dart';
import '../services/services.dart';
import 'circle_button.dart';

/// Header avatar: lime initials when signed in, dashed outline when not.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final auth = Services.of(context).auth;
    final c = context.colors;
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return CustomPaint(
            foregroundPainter: _DashedCircle(c.mist),
            child: CircleButton(
              key: const Key('profile-button'),
              tooltip: 'Profile, signed out',
              icon: Icons.person_outline_rounded,
              onPressed: onPressed,
              background: c.cobaltDeep,
              foreground: c.mist,
              borderColor: c.cobaltDeep,
            ),
          );
        }
        final initials = user.initials;
        return CircleButton(
          key: const Key('profile-button'),
          tooltip: 'Profile, signed in',
          onPressed: onPressed,
          background: c.lime,
          foreground: c.ink,
          borderColor: c.lime,
          child: initials.isEmpty
              ? const Icon(Icons.person_rounded)
              : Text(initials, style: SnippetFonts.display(14, color: c.ink)),
        );
      },
    );
  }
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const dashes = 16;
    const sweep = 2 * 3.141592653589793 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.5), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}
