import 'package:firebase_auth/firebase_auth.dart';

import 'auth_exception.dart';

/// Firebase error codes as messages people can act on.
AuthException firebaseAuthError(FirebaseAuthException e) => AuthException(
  switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'That email and password do not match.',
    'invalid-email' => 'Check the email address.',
    'missing-password' => 'Enter your password.',
    'email-already-in-use' => 'That email is already used by another account.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'Use 8+ characters with upper and lowercase letters and a number.',
    'requires-recent-login' => 'Sign in again, then try this change.',
    'user-token-expired' ||
    'invalid-user-token' => 'Your session expired. Sign in again to continue.',
    'operation-not-allowed' => 'This sign-in method is not available.',
    'user-mismatch' => 'Confirm with the account you are signed in to.',
    'user-disabled' => 'This account has been turned off.',
    'too-many-requests' => 'Too many tries. Wait a moment and try again.',
    'network-request-failed' => 'No connection. Check your internet.',
    _ => 'Could not complete that. Try again.',
  },
);
