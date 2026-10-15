import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/icons/google_logo.dart';
import '../../widgets/pill_button.dart';
import '../auth/sign_in_sheet.dart';

/// Bottom of Profile. What it offers depends on the account:
/// signed out → sign in; on this phone → sync with Google and clear cards;
/// Google → sign out and delete the account.
class AccountActions extends StatelessWidget {
  const AccountActions({super.key, required this.user});

  final AppUser? user;

  Future<void> _syncWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Links the "this phone only" session, so its cards come along.
      await Services.of(context).auth.signInWithGoogle();
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not sign in. Try again.')),
      );
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
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

  Future<void> _clearCards(BuildContext context) async {
    final library = Services.of(context).library;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      title: 'Clear saved cards?',
      body: 'This removes every card saved on this phone. It cannot be undone.',
      action: 'Clear',
    );
    if (!ok) return;
    try {
      await library.clear();
    } catch (e) {
      debugPrint('Could not clear cards: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not clear your cards. Try again.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final s = Services.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      title: 'Delete account and data?',
      body:
          'This removes every saved card and signs you out. It cannot be '
          'undone.',
      action: 'Delete',
    );
    if (!ok) return;
    try {
      await s.library.clear();
      await s.auth.deleteAccount();
    } catch (e) {
      debugPrint('Could not delete account: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not delete your account. Try again.'),
        ),
      );
      return;
    }
    navigator.popUntil((r) => r.isFirst);
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await Services.of(context).auth.signOut();
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final u = user;
    if (u == null) return _signedOut(context);
    if (u.isAnonymous) return _thisPhone(context);
    return _google(context);
  }

  Widget _signedOut(BuildContext context) {
    final c = context.colors;
    return PillButton(
      key: const Key('profile-sign-in'),
      label: 'Sign in',
      icon: Icons.login_rounded,
      onPressed: () => ensureSignedIn(context),
      background: c.lime,
      foreground: c.ink,
      height: 50,
      fontSize: 12.7,
    );
  }

  Widget _thisPhone(BuildContext context) {
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
            onPressed: () => _syncWithGoogle(context),
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
          context,
          key: const Key('profile-clear-cards'),
          label: 'Clear saved cards',
          onPressed: () => _clearCards(context),
        ),
      ],
    );
  }

  Widget _google(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillButton(
          key: const Key('sign-out'),
          label: 'Sign out',
          icon: Icons.logout_rounded,
          onPressed: () => _signOut(context),
          foreground: c.white,
          height: 50,
          fontSize: 12.7,
          borderWidth: 1,
        ),
        const SizedBox(height: 4),
        _link(
          context,
          key: const Key('profile-delete-account'),
          label: 'Delete account and data',
          onPressed: () => _deleteAccount(context),
        ),
      ],
    );
  }

  Widget _link(
    BuildContext context, {
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    final c = context.colors;
    return Center(
      child: TextButton(
        key: key,
        onPressed: onPressed,
        child: Text(
          label,
          style: SnippetFonts.body(
            10.7,
            color: c.mist,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
