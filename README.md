# Snippet

Bible verse quote cards. Pick a verse, style it, export a PNG, save or share.

- Offline: KJV and WEB texts are bundled as assets (no network needed).
- Pick any book, chapter, and verse range; toggle KJV / WEB.
- "Cobalt swipe" design: swipe up through 6 card styles (Vigil, Riso Loud, Dawn, Swiss,
  Night Watch, Cobalt Arch), sideways through each style's colourways.
- Export in three shapes (Feed 1:1, Portrait 4:5, Story 9:16), each laid out natively.
- Optional sign-in only gates the Library; picking, swiping and exporting never need it.
- Export as PNG (`RepaintBoundary` + `toImage`), save to gallery or share.
- Optional login and hot content updates are stubbed behind interfaces, ready for Firebase.

Package `snippet`, Android applicationId `com.arthur.snippet`, iOS bundle id `com.arthur.snippet`.

## Bible texts: public domain

The **King James Version (KJV)** and the **World English Bible (WEB)** are in the public domain.
The text files come from [eBible.org](https://ebible.org) verse-per-line downloads
(`eng-kjv_vpl.zip`, `eng-web_vpl.zip`) and are converted by `tool/build_bibles.py`.

- WEB: dedicated to the public domain; if you change the text you may not call it the "World English Bible".
- KJV: public domain worldwide except the UK, where the Crown holds letters patent over *printing*.
  (Cambridge/Oxford University Press and Collins hold the right to print it in the UK.)

The app code is MIT licensed (see `LICENSE`).

## Project structure

```
lib/
  main.dart                       entry point (Firebase.initializeApp goes here later)
  app.dart                        MaterialApp + dependency wiring
  core/                           app theme; theme/ holds color tokens + font styles
  cards/                          card design system: shapes, palettes/, styles/, QuoteCard
  data/                           Bible models/repository, saved cards, settings, JSON store
  features/
    home/                         verse of the day + "Pick a verse" panel (wheels, book sheet)
    swipe/                        style swiper (vertical styles, horizontal colourways)
    all_styles/                   every style at once, with filters
    export/                       "Share it" sheet: shape, Snippet mark, save/share PNG
    auth/                         optional sign-in sheet (shown on Save)
    library/                      saved cards grid + empty state
    profile/                      account, preferences, about
  widgets/                        shared chrome: header, arch panel/sheet, pills, switch, icons
  services/
    auth_service.dart             AuthService + LocalAuthService (no Firebase yet)
    content_config_service.dart   ContentConfigService + LocalContentConfigService (bundled defaults)
    firebase_content_config_service.dart  Remote Config: featured_verses, announcement
    export_service.dart           PNG capture, save to gallery (gal), share (share_plus)
    services.dart                 InheritedWidget container for the services above
assets/bibles/{kjv,web}.json      66 books; {id,name,license,books:[{id,name,chapters:[[verse,...]]}]}
assets/fonts/                     Syne, Instrument Serif/Sans, Cormorant Garamond, Space Mono,
                                  Bricolage Grotesque (all SIL OFL 1.1, licenses alongside)
tool/build_bibles.py              regenerates the JSON assets from eBible.org files
test/                             repository, export, and widget tests
```

## Develop

```
flutter pub get
flutter analyze
flutter test
flutter run
```

Requires the Flutter stable SDK (developed on 3.47) and, for device builds, the Android SDK / Xcode.
Android minSdk is 24 (required by the `gal` plugin).

## Next steps

### Firebase setup (not done yet)

1. Create a Firebase project; register Android (`com.arthur.snippet`) and iOS apps.
2. Enable Authentication providers: Anonymous and Google. Add your debug and release SHA-1/SHA-256 to the Android app.
3. Remote Config drives hot content. Parameters live in `remoteconfig.template.json`:
   `featured_verses` (JSON array of refs like `"PSA 46:10"`, `"LAM 3:22-23"`) and `announcement` (text, empty = none).
   Edit them in the console, or `firebase deploy --only remoteconfig` (this replaces the console template).
   New values reach users on their next launch; bad refs are skipped, and an empty list falls back to the bundled verses.
4. Run `flutterfire configure`; add `firebase_core`, `firebase_auth`, `google_sign_in`, `firebase_remote_config`.
5. Implement `FirebaseAuthService implements AuthService` and `FirebaseContentConfigService implements ContentConfigService`;
   call `Firebase.initializeApp()` in `main.dart` and pass them into `SnippetApp(auth: ..., contentConfig: ...)`.
6. `google-services.json` and `GoogleService-Info.plist` are git-ignored; do not commit them.
   Keep them in CI secrets or each developer's machine.

### Play Store signing / release checklist

- [ ] Final app name, short and full description, tagline (store listing name must be unique on Play).
- [ ] App icon (`flutter_launcher_icons`) and a feature graphic, 2+ phone screenshots.
- [ ] Create an upload keystore (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`).
- [ ] Create `android/key.properties` (git-ignored) and wire `signingConfigs.release` in `android/app/build.gradle.kts`.
- [ ] Enroll in Play App Signing; upload the AAB signed with the upload key.
- [ ] Bump `version:` in `pubspec.yaml` for each release (`name+buildNumber`).
- [ ] `flutter build appbundle --release`; test the release build on a real device (gallery save, share sheet).
- [ ] Privacy policy URL, Data safety form (no data collected until Firebase Auth is added), content rating, target audience.
- [ ] Internal testing track, then closed test (personal accounts need 12 testers for 14 days), then production.
- [ ] Attribution: mention public domain texts (KJV, WEB) in the listing or About screen.

## License

MIT, see [LICENSE](LICENSE). Bible texts are public domain (see above).
