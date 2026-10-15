import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/services.dart';
import '../../widgets/arch_sheet.dart';
import '../../widgets/icons/google_logo.dart';
import '../../widgets/pill_button.dart';

/// Returns true when a user is signed in, showing the optional sign-in
/// sheet first if needed. "Not now" returns false and keeps current work.
Future<bool> ensureSignedIn(BuildContext context) async {
  final auth = Services.of(context).auth;
  if (auth.currentUser != null) return true;
  final ok = await showArchSheet<bool>(
    context,
    padding: const EdgeInsets.fromLTRB(28, 44, 28, 12),
    builder: (_) => const SignInSheet(),
  );
  return ok ?? false;
}

/// "Keep it in your library": shown when saving while signed out.
class SignInSheet extends StatefulWidget {
  const SignInSheet({super.key});

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  bool _busy = false;

  Future<void> _google() async {
    final auth = Services.of(context).auth;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final user = await auth.signInWithGoogle();
      if (user != null) navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _thisPhoneOnly() async {
    final navigator = Navigator.of(context);
    await Services.of(context).auth.signInAnonymously();
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = Services.of(context).auth;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.lime, shape: BoxShape.circle),
          child: Icon(Icons.bookmark_border_rounded, color: c.cobalt, size: 26),
        ),
        const SizedBox(height: 18),
        Text(
          'Keep it in your library',
          textAlign: TextAlign.center,
          style: SnippetFonts.display(
            27,
            color: c.ink,
            letterSpacing: -1,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to save cards and pick up where you left off on any '
          'phone. Swiping and exporting never need an account.',
          textAlign: TextAlign.center,
          style: SnippetFonts.body(14, color: c.inkDim, height: 1.4),
        ),
        const SizedBox(height: 40),
        Opacity(
          opacity: auth.supportsGoogleSignIn ? 1 : 0.45,
          child: SizedBox(
            width: double.infinity,
            child: PillButton(
              key: const Key('google-sign-in'),
              label: 'Continue with Google',
              leading: const GoogleLogo(),
              onPressed: _busy || !auth.supportsGoogleSignIn ? null : _google,
              foreground: c.ink,
              background: c.white,
              outlined: true,
              labelStyle: SnippetFonts.body(14, weight: FontWeight.w600),
            ),
          ),
        ),
        if (!auth.supportsGoogleSignIn) ...[
          const SizedBox(height: 8),
          Text(
            'Google sign-in is not set up in this build yet.',
            style: SnippetFonts.body(12, color: c.inkDim),
          ),
          TextButton(
            key: const Key('local-sign-in'),
            onPressed: _thisPhoneOnly,
            child: Text(
              'Keep cards on this phone only',
              style: SnippetFonts.body(
                13,
                weight: FontWeight.w600,
                color: c.cobalt,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not now',
              style: SnippetFonts.display(
                12,
                weight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
