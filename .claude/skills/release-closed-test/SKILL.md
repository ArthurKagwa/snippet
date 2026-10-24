---
name: release-closed-test
description: Build Snippet's Android app bundle and upload/release it to Google Play closed testing (or internal/production) with fastlane. Use when asked to release, ship, upload, publish or push a new build to testers, the closed test, the alpha track or Play Console, to bump the build number for Play, or to check which version codes are on each Play track.
---

Releases go through `.claude/skills/release-closed-test/release.sh`, which
checks the key and working tree, runs `flutter test`, then the
`android/fastlane` `release` lane (version-code guard, `flutter build
appbundle --release`, `upload_to_play_store`), and prints the Play tracks
afterwards. Paths are relative to the repo root. macOS only (that's where
the signing key and Play key live); there is no CI release.

## Prerequisites

```bash
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_INSTALL_UPGRADE=1 brew install fastlane
```

- Upload signing: `android/key.properties` + its keystore (git-ignored,
  already on this Mac). Check a built bundle is signed with
  `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`
  (Owner `CN=Asasira Arthur, O=Snippet, C=UG`).
- Play API key: service account
  `play-publisher@snippet-79ab2.iam.gserviceaccount.com`, JSON key at
  `~/.config/snippet/play-service-account.json` (mode 600, outside the
  repo; override with `SNIPPET_PLAY_JSON_KEY`). It is invited in Play
  Console > Users and permissions with release access for Snippet. The
  user creates and manages this key, never the agent.

## Release (agent path)

1. Bump the build number: the `+N` in `version:` in `pubspec.yaml` must
   be higher than every version code on Play (see below). Commit it.
2. Run:

```bash
.claude/skills/release-closed-test/release.sh
```

Defaults: track `alpha` (closed testing), status `completed` (testers get
it as soon as it's processed). Options: `--track internal|production|<name>`,
`--draft` (review in Play Console before rollout), `--dry-run` (uploads and
validates on Play but commits nothing), `--skip-build` (reuse
`build/app/outputs/bundle/release/app-release.aab`), `--skip-tests`,
`--allow-dirty`. Takes 6-10 minutes: tests ~50 s, build 2.5 min warm /
5 min cold, upload ~3 min. Run it in the background.

Success ends with `Successfully finished the upload to Google Play` (a dry
run: `Successfully validated the upload to Google Play`), then the track
list, with the new code on `alpha` for a real release.

See what's on Play (read-only):

```bash
cd android && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 fastlane version_codes
```

Check the key alone:

```bash
cd android && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 fastlane check_key
```

## Release (human path)

Same lane by hand, from `android/` in a UTF-8 shell:
`fastlane release` (builds) or `fastlane release skip_build:true`.

## Gotchas

- **Run fastlane from `android/`, never the repo root.** At the root it
  asks "Would you like to set fastlane up?"; answering y creates an empty
  `./fastlane/` and then fails on the iOS project. Answer n and delete the
  folder. `release.sh` handles the `cd`.
- **Version codes are global across tracks.** Play rejects a code used on
  any track (internal held 4, alpha 7 at build 7). The `release` lane
  checks internal/alpha/beta/production first and stops with
  `pubspec.yaml build N is not above M`. A custom-named closed track is not
  in that list.
- **Whatever is in the working tree ships.** `release.sh` refuses
  uncommitted changes under `lib`, `pubspec.*`, `android/app`, `ios`,
  `assets/fonts`; commit first rather than reaching for `--allow-dirty`.
- **`--dry-run` still builds and uploads the whole bundle** (~3 min); it
  just doesn't commit the edit. Use it to test permissions or a new track
  name. It leaves that build in `build/app/outputs/bundle/release/`, so
  don't follow it with `--skip-build` unless `pubspec.yaml` is unchanged.
- **`--skip-build` uploads whatever bundle is on disk** without checking
  its version code against `pubspec.yaml`; only skip the build when you
  just built from the same commit.
- **Remote Config features gated by build.** `card_styles` serves newer
  layouts only to `app.build >= 7` (conditions `marker_text_android` /
  `marker_text_ios`). If a release adds a layout feature that old builds
  ignore, gate it the same way rather than changing the default value.
- **The 60 MB bundle can't go through browser automation** (Chrome
  extension upload limit is 10 MB), so fastlane is the only automated path.
- `google-services.json` (Firebase app config) is not the Play key.

## Troubleshooting

- `Google Api Error: Invalid request - The caller does not have permission`:
  the service account isn't invited in Play Console, lacks Snippet's
  release permission, or the invite hasn't propagated. Right after the
  invite it failed once and passed about a minute later; retry, then check
  Users and permissions.
- `Could not find service account json file at path ...` /
  `Invalid default value for json_key`: the key isn't at
  `~/.config/snippet/play-service-account.json`.
- `WARNING: fastlane requires your locale to be set to UTF-8`: export
  `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` (`release.sh` does).
- `brew install fastlane` -> `Refusing to load formula ... from untrusted
  tap mongodb/brew`: an unrelated tap; use the env vars in Prerequisites
  instead of trusting it.
