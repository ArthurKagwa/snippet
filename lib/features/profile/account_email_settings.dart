import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/arch_sheet.dart';
import 'change_email_sheet.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Account email actions, refreshed when returning from Firebase's web links.
class AccountEmailSettings extends StatefulWidget {
  const AccountEmailSettings({super.key, required this.user});

  final AppUser user;

  @override
  State<AccountEmailSettings> createState() => _AccountEmailSettingsState();
}

class _AccountEmailSettingsState extends State<AccountEmailSettings>
    with WidgetsBindingObserver {
  String? _running;
  String? _message;
  String? _error;
  String? _pendingEmail;

  bool get _busy => _running != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  Future<void> _run(String id, Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _running = id;
      _error = null;
    });
    try {
      final message = await action();
      if (mounted && message != null) setState(() => _message = message);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Account email action failed: $e');
      if (mounted) {
        setState(() => _error = 'Could not complete that. Try again.');
      }
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _refresh({bool silent = false}) {
    final auth = Services.of(context).auth;
    return _run('refresh', () async {
      final user = await auth.refreshUser();
      if (!mounted || user == null) return null;
      if (_pendingEmail?.toLowerCase() == user.email?.toLowerCase()) {
        setState(() => _pendingEmail = null);
        return 'Your email has been updated.';
      }
      if (silent) return null;
      return user.emailVerified
          ? 'Your email is verified.'
          : 'Not verified yet. Open the link in your email, then check again.';
    });
  }

  Future<void> _verify() {
    final auth = Services.of(context).auth;
    return _run('verify', () async {
      await auth.sendEmailVerification();
      return 'Verification link sent. Check your inbox and spam folder.';
    });
  }

  Future<void> _reset() {
    final auth = Services.of(context).auth;
    final email = widget.user.email!;
    return _run('reset', () async {
      await auth.sendPasswordReset(email);
      return 'If that email has an account, a reset link is on its way.';
    });
  }

  Future<void> _changeEmail() => _run('change', () async {
    final email = await showArchSheet<String>(
      context,
      builder: (_) => ChangeEmailSheet(user: widget.user),
    );
    if (email == null || !mounted) return null;
    setState(() => _pendingEmail = email);
    return 'Open the link at your new address to finish the change.';
  });

  Widget _action(String id, String label, VoidCallback onTap) => SettingsRow(
    key: Key('account-$id'),
    label: label,
    value: _running == id ? 'Please wait…' : null,
    onTap: _busy ? null : onTap,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = widget.user;
    return SettingsSection(
      title: 'Account',
      children: [
        SettingsRow(
          label: 'Email verification',
          value: user.emailVerified ? 'Verified' : 'Not verified',
        ),
        if (!user.emailVerified)
          _action('verify', 'Send verification email', _verify),
        _action('refresh', 'Check email status', () => _refresh()),
        _action('change', 'Change email', _changeEmail),
        if (user.usesPassword) _action('reset', 'Reset password', _reset),
        if (_pendingEmail != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Waiting for verification at $_pendingEmail. '
              'Keep using your current email until it is verified. '
              'You may need to sign in again with the new address.',
              style: SnippetFonts.body(12, color: c.mist, height: 1.4),
            ),
          ),
        if (_error != null || _message != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error ?? _message!,
                style: SnippetFonts.body(
                  12,
                  color: _error == null ? c.mist : c.danger,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
