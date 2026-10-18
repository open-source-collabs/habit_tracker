# iOS Release Checklist (needs a Mac)

The iOS project files were prepared on Windows and **have not been built**.
Work through this list on a Mac with Xcode before the first TestFlight upload.

## Already done in the repo
- `ios/Runner/Runner.entitlements` — iCloud Documents container
  `iCloud.co.trackfree.solforge`, wired via `CODE_SIGN_ENTITLEMENTS` for
  Debug, Release and Profile.
- `ios/Runner/Info.plist` — `GIDClientID` and the Google reversed-client-ID
  URL scheme, read from `ios/Flutter/GoogleSignIn.xcconfig` (optional,
  git-ignored); iPhone locked to portrait (iPad keeps all orientations).
- `ios/Runner/AppDelegate.swift` — sets the `UNUserNotificationCenter`
  delegate so reminders show in the foreground and taps reach the app.
- Google Drive is only offered on iOS when built with `GOOGLE_CLIENT_ID`.

## 1. One-time setup
1. `flutter pub get`, then `cd ios && pod install` — this generates
   `ios/Podfile` and `Podfile.lock`; **commit both**.
2. Open `ios/Runner.xcworkspace`, select the **Runner** target →
   *Signing & Capabilities*: choose your **Team** (sets `DEVELOPMENT_TEAM`).
3. Still in *Signing & Capabilities*, confirm **iCloud** shows
   *iCloud Documents* with container `iCloud.co.trackfree.solforge`. With
   automatic signing Xcode registers it; otherwise create the container in
   the Apple Developer portal and enable iCloud for the App ID
   `co.trackfree.solforge`.
4. Google Sign-In (optional): create an **iOS** OAuth client in Google Cloud
   (bundle id `co.trackfree.solforge`), then
   `cp ios/Flutter/GoogleSignIn.xcconfig.example ios/Flutter/GoogleSignIn.xcconfig`
   and fill in both values.

## 2. Build
```sh
flutter build ipa \
  --dart-define=ICLOUD_CONTAINER_ID=iCloud.co.trackfree.solforge \
  --dart-define=GOOGLE_CLIENT_ID=<ios client id> \
  --dart-define=PRIVACY_POLICY_URL=<hosted privacy_policy.html> \
  --dart-define=SUPPORT_EMAIL=<support address> \
  --dart-define=APP_STORE_ID=<numeric id, once the app record exists>
```
Leave out `GOOGLE_CLIENT_ID` if you aren't offering Google Drive sync on iOS.
Upload `build/ios/ipa/*.ipa` with Transporter or Xcode Organizer.

## 3. Verify on a device
- [ ] Fresh install shows onboarding; "Allow reminders" shows the iOS prompt.
- [ ] A reminder set 2 minutes ahead arrives with the app closed **and** while
      it is open (foreground delivery needs the delegate above).
- [ ] Tapping the reminder opens the app on that habit.
- [ ] iCloud sync: turn on, add a habit, see it on a second device.
- [ ] Google Drive sync (if configured): sign-in completes and returns.
- [ ] Settings → About: version, privacy policy, licenses, rate link.

## 4. App Store Connect
- **Privacy policy URL**: the hosted `docs/privacy_policy.html`.
- **App Privacy** ("nutrition label"): *Data Not Collected* — nothing is sent
  to the developer; iCloud/Drive sync goes to the user's own account.
- **Export compliance**: uses only standard HTTPS → exempt
  (`ITSAppUsesNonExemptEncryption` = NO is already set in Info.plist).
