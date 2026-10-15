import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/icons/google_logo.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/toast.dart';
import '../auth/sign_in_sheet.dart';
import 'password_confirm_dialog.dart';

/// Bottom of Profile. What it offers depends on the account:
/// signed out → sign in; on this phone → sync with Google and clear cards;
/// Google or email → sign out and delete the account (email accounts
/// confirm with their password first).
///
/// While one action runs it shows a spinner and the others are blocked.
class AccountActions extends StatefulWidget {
  const AccountActions({super.key, required this.user});

  final AppUser? user;

  @override
  State<AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<AccountActions> {
  /// Id of the action whose work is running; it shows the spinner.
  String? _running;

  /// True for the whole flow, including sheets and confirm dialogs that
  /// wait on the user (no spinner then), so nothing starts twice.
  bool _busy = false;

  Future<void> _guard(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _running = null;
        });
      }
    }
  }

  /// Real work is running (not just a sheet or dialog waiting on the
  /// user): other actions dim. Taps are always guarded by [_busy].
  bool get _working => _running != null;

  void _spin(String id) {
    if (mounted) setState(() => _running = id);
  }

  Future<void> _signIn() => _guard(() => ensureSignedIn(context));

  Future<void> _syncWithGoogle() {
    final auth = Services.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    return _guard(() async {
      _spin('sync');
      try {
        // Links the "this phone only" session, so its cards come along.
        await auth.signInWithGoogle();
      } catch (e) {
        debugPrint('Google sign-in failed: $e');
        showToast(messenger, 'Could not sign in. Try again.');
      }
    });
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _clearCards() {
    final library = Services.of(context).library;
    final messenger = ScaffoldMessenger.of(context);
    return _guard(() async {
      final ok = await _confirm(
        title: 'Clear saved cards?',
        body:
            'This removes every card saved on this phone. It cannot be '
            'undone.',
        action: 'Clear',
      );
      if (!ok) return;
      _spin('clear');
      try {
        await library.clear();
        showToast(messenger, 'Saved cards cleared');
      } catch (e) {
        debugPrint('Could not clear cards: $e');
        showToast(messenger, 'Could not clear your cards. Try again.');
      }
    });
  }

  Future<void> _deleteAccount() async {
    final s = Services.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var deleted = false;
    await _guard(() async {
      const title = 'Delete account and data?';
      const body =
          'This removes every saved card and signs you out. It cannot be '
          'undone.';
      final ok = widget.user?.usesPassword ?? false
          ? await confirmPasswordDialog(
              context,
              title: title,
              body: body,
              action: 'Delete',
            )
          : await _confirm(title: title, body: body, action: 'Delete');
      if (!ok) return;
      _spin('delete');
      try {
        await s.library.clear();
        await s.auth.deleteAccount();
        deleted = true;
      } catch (e) {
        debugPrint('Could not delete account: $e');
        showToast(messenger, 'Could not delete your account. Try again.');
      }
    });
    if (deleted) navigator.popUntil((r) => r.isFirst);
  }

  Future<void> _signOut() {
    final auth = Services.of(context).auth;
    final navigator = Navigator.of(context);
    return _guard(() async {
      _spin('sign-out');
      await auth.signOut();
      navigator.popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    if (u == null) return _signedOut();
    if (u.isAnonymous) return _thisPhone();
    return _google();
  }

  Widget _signedOut() {
    final c = context.colors;
    return PillButton(
      key: const Key('profile-sign-in'),
      label: 'Sign in',
      icon: Icons.login_rounded,
      onPressed: _working
          ? null
          : () {
              _signIn();
            },
      busy: _running == 'sign-in',
      background: c.lime,
      foreground: c.ink,
      height: 50,
      fontSize: 12.7,
    );
  }

  Widget _thisPhone() {
    final c = context.colors;
    final canSync = Services.of(context).auth.supportsGoogleSignIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSync) ...[
          PillButton(
            key: const Key('profile-sync-google'),
            label: 'Sync with Google',
            leading: const GoogleLogo(),
            onPressed: _working
                ? null
                : () {
                    _syncWithGoogle();
                  },
            busy: _running == 'sync',
            background: c.white,
            foreground: c.ink,
            height: 50,
            labelStyle: SnippetFonts.body(14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your cards if you change phones.',
            textAlign: TextAlign.center,
            style: SnippetFonts.body(11, color: c.mist),
          ),
          const SizedBox(height: 4),
        ],
        _link(
          id: 'clear',
          key: const Key('profile-clear-cards'),
          label: 'Clear saved cards',
          onPressed: _clearCards,
        ),
      ],
    );
  }

  Widget _google() {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillButton(
          key: const Key('sign-out'),
          label: 'Sign out',
          icon: Icons.logout_rounded,
          onPressed: _working
              ? null
              : () {
                  _signOut();
                },
          busy: _running == 'sign-out',
          foreground: c.white,
          height: 50,
          fontSize: 12.7,
          borderWidth: 1,
        ),
        const SizedBox(height: 4),
        _link(
          id: 'delete',
          key: const Key('profile-delete-account'),
          label: 'Delete account and data',
          onPressed: _deleteAccount,
        ),
      ],
    );
  }

  /// Underlined text action; spins while its own work runs, dims while
  /// another action runs.
  Widget _link({
    required String id,
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    final c = context.colors;
    return Center(
      child: AnimatedOpacity(
        opacity: _working && _running != id ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: TextButton(
          key: key,
          onPressed: _working ? null : onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running == id) ...[
                SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: c.mist,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: SnippetFonts.body(
                  10.7,
                  color: c.mist,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
