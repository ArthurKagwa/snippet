/// Minimal user model, independent of any auth SDK.
class AppUser {
  const AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.isAnonymous = false,
    this.usesPassword = false,
    this.emailVerified = false,
  });

  final String id;
  final String? displayName;
  final String? email;
  final bool isAnonymous;

  /// Signed in with email and password (not Google).
  final bool usesPassword;

  /// Whether Firebase has verified the current email address.
  final bool emailVerified;

  /// Password accounts finish setup only after verifying their address.
  bool get requiresEmailVerification =>
      !isAnonymous && usesPassword && !emailVerified;

  /// "DM" for "Daniel Mugisha"; empty when there is no name.
  String get initials {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }
}
