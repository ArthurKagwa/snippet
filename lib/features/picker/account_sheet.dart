import 'package:flutter/material.dart';

import '../../services/services.dart';

/// Optional sign-in. Backed by [AuthService]; local no-op until Firebase is set up.
Future<void> showAccountSheet(BuildContext context) {
  final auth = Services.of(context).auth;
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StreamBuilder(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (ctx, snap) {
        final user = snap.data;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account (optional)',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  user == null
                      ? 'Signing in is optional. Snippet works fully without it.'
                      : user.isAnonymous
                      ? 'Signed in anonymously.'
                      : 'Signed in as ${user.displayName ?? user.id}.',
                ),
                const SizedBox(height: 12),
                if (user == null) ...[
                  FilledButton(
                    onPressed: auth.signInAnonymously,
                    child: const Text('Continue anonymously'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: auth.supportsGoogleSignIn
                        ? auth.signInWithGoogle
                        : null,
                    child: Text(
                      auth.supportsGoogleSignIn
                          ? 'Sign in with Google'
                          : 'Google sign-in (not configured yet)',
                    ),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: auth.signOut,
                    child: const Text('Sign out'),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
