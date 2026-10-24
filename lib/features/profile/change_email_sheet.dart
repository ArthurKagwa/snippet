import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/pill_button.dart';
import '../auth/auth_field_decoration.dart';

/// Reauthenticates before Firebase sends a verification link to a new address.
class ChangeEmailSheet extends StatefulWidget {
  const ChangeEmailSheet({super.key, required this.user});

  final AppUser user;

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return setState(() => _error = 'Check the new email address.');
    }
    if (email.toLowerCase() == widget.user.email?.toLowerCase()) {
      return setState(() => _error = 'Enter a different email address.');
    }
    if (widget.user.usesPassword && _password.text.isEmpty) {
      return setState(() => _error = 'Enter your current password.');
    }
    final auth = Services.of(context).auth;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.changeEmail(email, password: _password.text);
      if (mounted) Navigator.of(context).pop(email);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Email change failed: $e');
      if (mounted) {
        setState(() => _error = 'Could not change your email. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Change email',
            style: SnippetFonts.display(27, color: c.ink, letterSpacing: -1),
          ),
          const SizedBox(height: 12),
          Text(
            'We’ll send a link to your new address. Your email changes only '
            'after you open that link and verify it.'
            '${widget.user.usesPassword ? '' : ' Confirm with Google to continue.'}',
            style: SnippetFonts.body(14, color: c.inkDim, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('new-email-field'),
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: widget.user.usesPassword
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: widget.user.usesPassword ? null : (_) => _submit(),
            style: SnippetFonts.body(15, color: c.ink),
            cursorColor: c.cobalt,
            decoration: authFieldDecoration(c, 'New email'),
          ),
          if (widget.user.usesPassword) ...[
            const SizedBox(height: 10),
            TextField(
              key: const Key('current-password-field'),
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: SnippetFonts.body(15, color: c.ink),
              cursorColor: c.cobalt,
              decoration: authFieldDecoration(c, 'Current password'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: SnippetFonts.body(13, color: c.danger),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PillButton(
            key: const Key('change-email-submit'),
            label: 'Send verification link',
            onPressed: _busy ? null : _submit,
            busy: _busy,
            background: c.cobalt,
            foreground: c.white,
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
