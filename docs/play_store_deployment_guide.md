# Google Play Store Deployment Guide for Track Free

This guide provides end-to-end instructions for signing, building, and publishing **Track Free** (`co.trackfree.solforge`) to the Google Play Store.

---

## 1. Prerequisites Checklist

- [x] **Target SDK**: Configured to API 35 (Android 15), exceeding Google Play's API 34 minimum.
- [x] **Minimum SDK**: Configured to API 21 (covers 99.5%+ of active devices).
- [x] **R8 / ProGuard Minification**: Enabled with `proguard-rules.pro` optimizing code and shrinking APK/bundle size.
- [x] **Adaptive Launcher Icon**: "Bento Check" mark in `mipmap-anydpi-v26/` (foreground, background and Android 13 monochrome layers). Store icon: `assets/branding/store/play_store_icon_512.png`. Regenerate all raster icons with `flutter test tool/generate_brand_assets.dart` (see `assets/branding/README.md`).
- [x] **Permissions**: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, and `INTERNET`.
- [x] **Security**: Cleartext traffic disabled (`usesCleartextTraffic="false"`) and `allowBackup="false"`.

---

## 2. Generating Your Upload Keystore

Run the following command in PowerShell / Terminal to create your upload keystore:

### On Windows (PowerShell):
```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### On macOS / Linux:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> [!CAUTION]
> **Keep your keystore and passwords safe!** If you lose this keystore or forget your password, you will not be able to publish updates to your app unless you reset the upload key via Google Play Console support.

---

## 3. Configuring `key.properties`

1. Create a file named `key.properties` inside the `android/` directory:
   `android/key.properties`

2. Add your keystore credentials:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=app/upload-keystore.jks
   ```

*(Note: `android/key.properties` and `*.jks` are already added to `.gitignore` so your secrets will never be committed to git).*

---

## 4. Building the Production App Bundle (.aab)

Google Play Store requires an **Android App Bundle (.aab)** for publishing:

```bash
flutter build appbundle --release
```

The output file will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

> [!NOTE]
> If `key.properties` is present, Flutter will automatically sign the bundle with your upload key. If absent, it gracefully uses the debug key for testing.

To build an APK for local testing on a physical device:
```bash
flutter build apk --release
```

---

## 5. Google Play Console Submission Checklist

### A. App Details
- **App Name**: Track Free
- **Short Description**: Minimalist Bento habit tracker with privacy-first offline storage.
- **Full Description**: Track Free is a beautifully designed Bento habit tracker built with privacy in mind. Features offline SQLite storage, custom habit frequency, streaks, dark mode themes, home screen widgets, and optional encrypted cloud backup.
- **Category**: Productivity / Lifestyle

### B. Policy Declarations
1. **Exact Alarms (`SCHEDULE_EXACT_ALARM`)**:
   - In **App Content > Special App Access / Exact Alarms**, declare:
     - **Use Case**: *Alarms & Timers / Habit Reminders*
     - **Explanation**: "Track Free schedules timely daily habit notifications and streak reminders at specific user-configured times."
2. **Data Safety**:
   - Track Free stores data locally in SQLite on the user's device.
   - If Google Drive Sync is turned on by the user, the app communicates with the user's personal Google Drive App Data folder. No third-party ad tracking or analytics SDKs collect personal data.
3. **Target Audience**: 13 and older.

### C. Release Tracks
1. Upload `app-release.aab` to **Internal Testing**.
2. Add your email as an internal tester to test installation directly from Google Play.
3. Promote to **Closed Testing** or **Production** once validated.
