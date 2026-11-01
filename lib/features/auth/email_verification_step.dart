import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/pill_button.dart';

/// Keeps setup pending until Firebase confirms the signed-in email address.
class EmailVerificationStep extends StatefulWidget {
  const EmailVerificationStep({
    super.key,
    required this.user,
    required this.onVerified,
    required this.onSignedOut,
  });

  final AppUser user;
  final VoidCallback onVerified;
  final VoidCallback onSignedOut;

  @override
  State<EmailVerificationStep> createState() => _EmailVerificationStepState();
}

class _EmailVerificationStepState extends State<EmailVerificationStep>
    with WidgetsBindingObserver {
  String? _running;
  String? _message;
  String? _error;
  bool _completed = false;

  bool get _busy => _running != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(silent: true);
  }

  Future<void> _run(
    String id,
    Future<void> Function(AuthService) action,
  ) async {
    if (_busy || _completed) return;
    final auth = Services.of(context).auth;
    setState(() {
      _running = id;
      _error = null;
    });
    try {
      await action(auth);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Email verification failed: $e');
      if (mounted) {
        setState(() => _error = 'Could not complete that. Try again.');
      }
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _check({bool silent = false}) => _run('check', (auth) async {
    final user = await auth.refreshUser();
    if (!mounted) return;
    if (user == null || user.id != widget.user.id) {
      widget.onSignedOut();
    } else if (user.emailVerified && !user.isAnonymous) {
      _completed = true;
      widget.onVerified();
    } else if (!silent) {
      setState(() {
        _message =
            'Not verified yet. Open the link in your email, then try again.';
      });
    }
  });

  Future<void> _resend() => _run('resend', (auth) async {
    await auth.sendEmailVerification();
    if (mounted) {
      setState(() {
        _message = 'Verification link sent. Check your inbox and spam folder.';
      });
    }
  });

  Future<void> _signOut() => _run('sign-out', (auth) async {
    await auth.signOut();
    if (mounted) widget.onSignedOut();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      key: const Key('email-verification-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your email',
          style: SnippetFonts.display(27, color: c.ink, letterSpacing: -1),
        ),
        const SizedBox(height: 12),
        Text(
          'Open the verification link sent to ${widget.user.email} to finish '
          'setting up your account and save cards. Then come back here.',
          style: SnippetFonts.body(14, color: c.inkDim, height: 1.4),
        ),
        if (_error != null || _message != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _error ?? _message!,
              style: SnippetFonts.body(
                13,
                color: _error != null ? c.danger : c.inkDim,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        PillButton(
          key: const Key('verification-check'),
          label: 'I’ve verified my email',
          busy: _running == 'check',
          onPressed: _busy ? null : () => _check(),
          background: c.cobalt,
          foreground: c.white,
        ),
        TextButton(
          key: const Key('verification-resend'),
          onPressed: _busy ? null : _resend,
          child: Text(_running == 'resend' ? 'Sending…' : 'Resend email'),
        ),
        TextButton(
          key: const Key('verification-sign-out'),
          onPressed: _busy ? null : _signOut,
          child: const Text('Use a different account'),
        ),
        TextButton(
          key: const Key('verification-not-now'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
