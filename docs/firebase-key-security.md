# Firebase client API keys

Reviewed October 24, 2026 for GitHub secret-scanning alerts
[#1](https://github.com/ArthurKagwa/snippet/security/secret-scanning/1) (Android)
and [#2](https://github.com/ArthurKagwa/snippet/security/secret-scanning/2) (iOS).

Both alerts were resolved as `wont_fix` with the verified public-client-key
rationale recorded on GitHub. The keys were not revoked.

These keys identify the Firebase project used by the mobile apps. They remain
active because installed apps need them. Google documents that
[Firebase client API keys may be public](https://firebase.google.com/docs/projects/api-keys)
when restricted to Firebase services. They do not authorize access to user data;
Firebase Authentication and deployed Security Rules enforce that access.

## Verified configuration

- Both alert values match the corresponding Android and iOS Firebase client
  keys in Google Cloud project `snippet-79ab2`.
- Both keys have API allowlists. The unused Cloud SQL Admin API was removed
  from each allowlist on October 24, 2026; all other API entries were preserved.
- Neither allowlist includes `generativelanguage.googleapis.com` (Gemini).
- The deployed Firestore rules require an authenticated user matching the
  document owner's UID. Paths outside `users/{uid}/cards/{cardId}` are denied.
- The deployed rules do not yet include the email-verification write condition
  present in the local `firestore.rules`; that change needs its own deployment.
- These keys currently have no package/signing-certificate or bundle-ID
  restrictions. The Flutter app does not currently initialize App Check.

The generated config file was removed from Git tracking in commit `d07533c` on
October 15, 2026. It and the native config files are ignored; the committed Dart
template contains placeholders. Earlier commits still contain the client keys.
Removing a file does not automatically close a GitHub secret-scanning alert.

## Keeping the configuration safe

Keep non-Firebase services, especially Gemini, off these client key allowlists.
Use separate restricted keys for those services and keep server credentials on
the server. Re-check restrictions whenever adding a Google API to the project.

App Check and application restrictions are additional hardening work. Roll them
out with tested Android and iOS builds, including Play signing certificates and
release bundle IDs, before enforcing them for installed clients.

Do not revoke or rotate a key solely to remove this client-configuration alert.
If evidence of misuse or unintended API access warrants rotation, coordinate
replacement config and an app release first; deleting an active key can break
Firebase calls in already installed versions.

Validation covered live API-key metadata and deployed Firestore rule source.
It did not include a mobile end-to-end test or an audit of historical usage.
