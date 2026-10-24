import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/overlay_toast.dart';
import '../../widgets/pill_button.dart';
import 'auth_field_decoration.dart';
import 'password_guide.dart';

/// Email and password sign-in for the sign-in sheet, with a switch to
/// create an account (password rules checklist and a confirm field) and a
/// password reset link. Errors show under the fields.
class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({super.key, required this.onSignedIn, this.onBack});

  final VoidCallback onSignedIn;

  /// Back to the other sign-in options; hidden when null.
  final VoidCallback? onBack;

  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _create = false;
  bool _obscure = true;
  String? _error;

  /// 'submit' or 'reset' while that request runs.
  String? _running;

  bool get _busy => _running != null;

  static final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _check({required bool needPassword}) {
    if (!_emailShape.hasMatch(_email.text.trim())) {
      return 'Check the email address.';
    }
    if (!needPassword) return null;
    if (_password.text.isEmpty) return 'Enter your password.';
    if (!_create) return null;
    if (!meetsPasswordRules(_password.text)) {
      return 'Choose a password that ticks every point above.';
    }
    if (_confirm.text != _password.text) return 'The passwords do not match.';
    return null;
  }

  Future<void> _run(String id, Future<void> Function(AuthService) work) async {
    if (_busy) return;
    final auth = Services.of(context).auth;
    setState(() {
      _running = id;
      _error = null;
    });
    try {
      await work(auth);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      if (mounted) setState(() => _error = 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _submit() async {
    final problem = _check(needPassword: true);
    if (problem != null) return setState(() => _error = problem);
    await _run('submit', (auth) async {
      final email = _email.text;
      final password = _password.text;
      if (_create) {
        await auth.createAccountWithEmail(email, password);
        // Keep the created account so delivery can be retried in the
        // verification step without attempting registration again.
        var message =
            'Account created. Check your email for a verification link.';
        try {
          await auth.sendEmailVerification();
        } catch (e) {
          debugPrint('Verification email failed: $e');
          message = 'Account created. Use Resend email to try again.';
        }
        if (mounted) showOverlayToast(context, message);
      } else {
        await auth.signInWithEmail(email, password);
      }
      if (mounted) widget.onSignedIn();
    });
  }

  Future<void> _reset() async {
    final problem = _check(needPassword: false);
    if (problem != null) {
      return setState(() => _error = 'Enter your email above first.');
    }
    await _run('reset', (auth) async {
      await auth.sendPasswordReset(_email.text);
      if (mounted) {
        showOverlayToast(
          context,
          'If that email has an account, a reset link is on its way.',
        );
      }
    });
  }

  Widget _visibility(SnippetColors c) => IconButton(
    tooltip: _obscure ? 'Show password' : 'Hide password',
    icon: Icon(
      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: c.inkDim,
    ),
    onPressed: () => setState(() => _obscure = !_obscure),
  );

  Widget _link(SnippetColors c, String label, VoidCallback? onPressed) =>
      TextButton(
        onPressed: _busy ? null : onPressed,
        child: Text(
          label,
          style: SnippetFonts.body(
            13,
            weight: FontWeight.w600,
            color: _busy ? c.inkDim : c.cobalt,
            decoration: TextDecoration.underline,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final error = _error;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('email-field'),
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            style: SnippetFonts.body(15, color: c.ink),
            cursorColor: c.cobalt,
            decoration: authFieldDecoration(c, 'Email'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('password-field'),
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: _create
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: [
              _create ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onSubmitted: _create ? null : (_) => _submit(),
            style: SnippetFonts.body(15, color: c.ink),
            cursorColor: c.cobalt,
            decoration: authFieldDecoration(
              c,
              'Password',
              suffix: _visibility(c),
            ),
          ),
          if (_create) ...[
            ListenableBuilder(
              listenable: _password,
              builder: (_, _) => PasswordGuide(password: _password.text),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: Listenable.merge([_password, _confirm]),
              builder: (_, _) => TextField(
                key: const Key('confirm-field'),
                controller: _confirm,
                enabled: !_busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                style: SnippetFonts.body(15, color: c.ink),
                cursorColor: c.cobalt,
                decoration: authFieldDecoration(
                  c,
                  'Confirm password',
                  errorText:
                      _confirm.text.isNotEmpty &&
                          _confirm.text != _password.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                key: const Key('email-error'),
                style: SnippetFonts.body(13, color: c.danger),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PillButton(
            key: const Key('email-submit'),
            label: _create ? 'Create account' : 'Sign in',
            onPressed: _busy ? null : _submit,
            busy: _running == 'submit',
            background: c.cobalt,
            foreground: c.white,
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _link(
                c,
                _create
                    ? 'Have an account? Sign in'
                    : 'New here? Create an account',
                () => setState(() {
                  _create = !_create;
                  _confirm.clear();
                  _error = null;
                }),
              ),
              if (!_create) _link(c, 'Forgot password?', _reset),
            ],
          ),
          if (widget.onBack != null)
            _link(c, 'Other ways to sign in', widget.onBack),
        ],
      ),
    );
  }
}
