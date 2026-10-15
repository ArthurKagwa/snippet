import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/arch_sheet.dart';
import '../../widgets/icons/google_logo.dart';
import '../../widgets/overlay_toast.dart';
import '../../widgets/pill_button.dart';
import 'email_sign_in_form.dart';

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
  /// 'google' or 'local' while that sign-in runs; every option waits.
  String? _running;

  bool get _busy => _running != null;

  /// Showing the email and password form instead of the other options.
  bool _email = false;

  Future<void> _signIn(String id, Future<bool> Function() attempt) async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    setState(() => _running = id);
    try {
      if (await attempt()) navigator.pop(true);
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      if (mounted) showOverlayToast(context, 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _google() {
    final auth = Services.of(context).auth;
    return _signIn('google', () async => await auth.signInWithGoogle() != null);
  }

  Future<void> _thisPhoneOnly() {
    final auth = Services.of(context).auth;
    return _signIn('local', () async {
      await auth.signInAnonymously();
      return true;
    });
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
        SizedBox(height: _email ? 24 : 40),
        if (_email)
          EmailSignInForm(
            onSignedIn: () => Navigator.of(context).pop(true),
            onBack: auth.supportsGoogleSignIn
                ? () => setState(() => _email = false)
                : null,
          )
        else
          ..._options(auth),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'Not now',
              style: SnippetFonts.display(
                12,
                weight: FontWeight.w700,
                color: _busy ? c.inkDim : c.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Google first, then email, then "this phone only" where Google is
  /// missing.
  List<Widget> _options(AuthService auth) {
    final c = context.colors;
    return [
      SizedBox(
        width: double.infinity,
        child: PillButton(
          key: const Key('google-sign-in'),
          label: 'Continue with Google',
          leading: const GoogleLogo(),
          onPressed: _busy || !auth.supportsGoogleSignIn ? null : _google,
          busy: _running == 'google',
          foreground: c.ink,
          background: c.white,
          outlined: true,
          labelStyle: SnippetFonts.body(14, weight: FontWeight.w600),
        ),
      ),
      if (auth.supportsEmailSignIn) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: PillButton(
            key: const Key('email-sign-in'),
            label: 'Continue with email',
            icon: Icons.mail_outline_rounded,
            onPressed: _busy ? null : () => setState(() => _email = true),
            foreground: c.ink,
            background: c.white,
            outlined: true,
            labelStyle: SnippetFonts.body(14, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
      ],
      if (!auth.supportsGoogleSignIn) ...[
        const SizedBox(height: 8),
        Text(
          'Google sign-in is not set up in this build yet.',
          style: SnippetFonts.body(12, color: c.inkDim),
        ),
        TextButton(
          key: const Key('local-sign-in'),
          onPressed: _busy ? null : _thisPhoneOnly,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running == 'local') ...[
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.cobalt,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  'Keep cards on this phone only',
                  style: SnippetFonts.body(
                    13,
                    weight: FontWeight.w600,
                    color: _busy && _running != 'local' ? c.inkDim : c.cobalt,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }
}
