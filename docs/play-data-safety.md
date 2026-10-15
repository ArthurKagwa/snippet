# Play Console: Data safety answers

What to enter in **Play Console → App content → Data safety** for Snippet.
Keep this file in step with [privacy-policy.md](privacy-policy.md) and the
SDKs in `pubspec.yaml`; change both whenever data handling changes.

## Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (Firebase uses HTTPS/TLS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** |
| Account deletion URL | `https://snippetverses.app/delete-account` |

## Data types

Declare only these. Nothing is **shared**: Google processes data for us as a
service provider, which Play does not count as sharing.

| Category → type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |
| --- | --- | --- | --- | --- | --- |
| Personal info → **Name** | Yes | No | No | Optional (Google sign-in) | App functionality, Account management |
| Personal info → **Email address** | Yes | No | No | Optional (Google sign-in) | App functionality, Account management |
| Personal info → **User IDs** | Yes | No | No | Optional (Google or "this phone only" sign-in) | App functionality, Account management |
| App activity → **Other user-generated content** (saved cards) | Yes | No | No | Optional (only when signed in with Google) | App functionality |
| Device or other IDs → **Device or other IDs** (Firebase installation ID, used by Remote Config) | Yes | No | No | Required | App functionality |

Not collected (leave unchecked): location, financial info, health, messages,
photos/videos, audio, files and docs, calendar, contacts, web browsing, app
interactions/search history/installed apps, crash logs, diagnostics, other
performance data.

## Why each answer

- **Name, email, user ID**: Firebase Authentication receives them on Google
  sign-in (`lib/services/firebase_auth_service.dart`). "Keep cards on this
  phone only" creates an anonymous Firebase user ID, with no name or email.
  Google also passes a profile photo link; it is a URL, not an image file, so
  it is not the "Photos" data type.
- **Saved cards**: `users/{uid}/cards/{cardId}` in Firestore
  (`lib/data/saved_card.dart`, `firestore.rules`), only for Google accounts.
  Phone-only cards live in a local file (`lib/app.dart`).
- **Installation ID**: Firebase Remote Config generates one to fetch the verse
  of the day and announcements.
- **Not collected**: exported images go to the gallery or share sheet on the
  device; the reminder schedule is local (`flutter_local_notifications`); no
  analytics, ads or crash-reporting SDKs are included.

## Other App content items

- **Privacy policy URL**: `https://snippetverses.app/privacy` (also linked
  in the app under Profile → About → Privacy policy).
- **Ads**: No ads.
- **Target audience**: 13+ (the policy says the app is not directed at
  children under 13).
