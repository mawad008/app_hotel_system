# Hotel Guest App — Store Release Guide

How to build and ship the app to Google Play and the App Store.

## Toolchain

- **Flutter 3.44 or newer** (the lockfile requires Dart ≥ 3.13.2; verified with
  Flutter 3.47.6). An older SDK fails at `flutter pub get`.
- Android: JDK 17, Android SDK with platform 36.
- iOS: a Mac with Xcode and CocoaPods. iOS cannot be built on Windows.

## Identity

| | Android | iOS |
|---|---|---|
| Id | `com.hotelsystem.hotel_guest_app` | `com.hotelsystem.hotelGuestApp` |
| Name (en / ar) | Hotel System / فندق سيستم | Hotel System / فندق سيستم |
| Team | — | `549WCU26VB` |

Both ids are **permanent once the first build is uploaded**. Change them before
that, or never.

## Version

`version:` in `pubspec.yaml` is `<name>+<build>` (e.g. `1.0.0+1`). Every upload
to either store needs a build number higher than the last one uploaded.

## Production configuration

Release builds must be given the production defines:

```
--dart-define-from-file=config/production.json
```

Without it the app points at the local development backend
(`http://10.0.2.2:8000`) and nothing loads.

## Android

### Signing

`android/app/build.gradle.kts` signs release builds with the keystore named in
`android/key.properties`. Both the keystore and `key.properties` are git-ignored
— copy `android/key.properties.example` and fill it in:

```
storeFile=upload-keystore.jks      # relative to android/
storePassword=…
keyAlias=upload
keyPassword=…
```

Keep the keystore and its passwords in a password manager. With Play App
Signing (the default for new apps) this is only the *upload* key: if it is lost,
Google can reset it, but every upload until then is blocked.

Without `key.properties` a release build falls back to the debug key so
`flutter run --release` still works — Play rejects such a bundle.

### Build

```
flutter build appbundle --release --dart-define-from-file=config/production.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

### Play Console

1. Create the app (default language, app name, free/paid).
2. *Production → Create new release*, upload the `.aab`, accept Play App Signing.
3. Store listing — the graphics are in `store/google-play/`:
   - `icon-512.png` — app icon
   - `feature-graphic-1024x500.png` — feature graphic
   - `phone-screenshots/ar/` and `phone-screenshots/en/` — phone screenshots
     (1080×2160, taken from the release build against the production API;
     upload each set to its own listing language)
4. App content declarations:
   - **Privacy policy URL** (required — the app uses the camera).
   - **Data safety**: phone number, name, email (account); ID document and
     selfie photos (identity verification); booking and payment details.
   - **Permissions**: `CAMERA` only. The microphone permission the camera plugin
     declares is removed in the manifest.
   - Content rating questionnaire, target audience, ads (none).
5. App access: reviewers need a way past the phone OTP — give them a test
   number and code.

## iOS

Run on a Mac:

```
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release \
  --dart-define-from-file=config/production.json \
  --export-options-plist=ios/ExportOptions.plist
```

Upload `build/ios/ipa/*.ipa` with Transporter, or open
`build/ios/archive/Runner.xcarchive` in Xcode → *Distribute App*.

Already configured in the project:

- Automatic signing, team `549WCU26VB`, iOS 15.0 minimum.
- **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`). The UI is a phone design, and
  iPad support cannot be withdrawn once shipped; add it in a later version if
  wanted (it then needs iPad screenshots).
- `ITSAppUsesNonExemptEncryption = false` (HTTPS only), so App Store Connect
  does not ask the export-compliance question per build.
- Purpose strings for camera (used), and microphone / photo library (not used —
  present because the camera plugins link those APIs, see `Info.plist`),
  localised in `en.lproj` / `ar.lproj`.
- App icon set without alpha channel.

Still to do in App Store Connect: create the app record for the bundle id,
privacy policy URL, App Privacy answers (same data as Play's Data safety),
6.9" iPhone screenshots, and a demo account for App Review.

## Icons and store graphics

All icons and the feature graphic are generated from the vector brand mark:

```
python tool/generate_store_assets.py      # requires Pillow
```

Re-run it if the mark in `lib/core/widgets/brand_logo.dart` /
`android/.../drawable/launch_logo.xml` changes.

## Login session

The guest signs in once. The access token is kept in the Keychain (iOS) /
Keystore-encrypted storage (Android) by `SecureTokenStore`, together with a
snapshot of the last profile the backend confirmed:

- Cold start, backend reachable → the session is rebuilt from `GET /guest/auth/me`.
- Cold start, backend unreachable (offline, timeout, 5xx, 429) → the guest stays
  signed in from the snapshot.
- The backend answers `401` → the token is dropped and the guest signs in again.
- Android app data is excluded from cloud backup and device transfer: the
  Keystore key never leaves the device, so a restored token could not be read.
  A guest signs in again on a new phone.
