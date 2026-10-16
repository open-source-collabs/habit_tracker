# Cloud Sync Setup

Sync is optional and works through the user's **own** cloud storage:

- **Google Drive App Data folder**: a hidden, app-scoped folder. The app can only see the files it created there.
- **iCloud Documents**: the app's container in the user's iCloud Drive.

There is no server and no account with us. Without the configuration below, the app runs fully offline and the Sync tab says that cloud sync isn't available on the device. Nothing breaks.

## How it works

The code lives in `lib/features/sync/`.

| Piece | Role |
| :--- | :--- |
| `domain/merge_engine.dart` | Merges two payloads. Each check-in day resolves by its change time, so un-checks propagate. Tombstones make deletions propagate. Habit and theme details resolve by `lastModifiedAt`. The merge is commutative and idempotent. |
| `domain/sync_engine.dart` | One pass: download, merge into local data, then upload only if the cloud copy differs. It refuses cloud data from a newer app version. It never overwrites a cloud copy it can't read. |
| `data/cloud_sync_backend.dart` | The transport interface, plus `SyncConfig` (build-time settings). |
| `data/google_drive_backend.dart`, `data/drive_app_data_client.dart` | Google Sign-In (scope `drive.appdata` only) and Drive REST v3. |
| `data/icloud_backend.dart` | iCloud Documents via the `icloud_storage` plugin. |
| `presentation/providers/sync_controller.dart` | Opt-in per device. Syncs at launch, on resume, 5 s after local edits, and on **Sync now**. |

The synced file is `habit_tracker_sync.json`, schema v2 (see `AppPayloadModel`).

## 0. Prerequisite: a real app identifier

Both providers tie credentials to the app ID. Replace the template IDs first:

- **Android:** `namespace` and `applicationId` in `android/app/build.gradle.kts` (currently `com.example.habit_tracker`).
- **iOS/macOS:** `PRODUCT_BUNDLE_IDENTIFIER` in Xcode (currently `com.example.habitTracker`).

## 1. Google Drive (Android, also iOS/macOS)

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project.
2. Enable the **Google Drive API**.
3. Configure the **OAuth consent screen** and add the scope `https://www.googleapis.com/auth/drive.appdata`.
4. Create the OAuth client IDs:
   - **Web application**: its client ID is the `GOOGLE_SERVER_CLIENT_ID`. Android requires it.
   - **Android**: the package name plus the SHA-1 of each signing key (debug and release). Get the SHA-1 with `cd android && ./gradlew signingReport`.
   - **iOS** (optional): add `GIDClientID` and the reversed-client-ID URL scheme to `ios/Runner/Info.plist`, as described in the `google_sign_in_ios` README.
5. Build with the web client ID:
   ```sh
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=1234-abc.apps.googleusercontent.com
   ```

## 2. iCloud (iOS, macOS)

1. In the Apple Developer portal:
   - Create an **iCloud container**, e.g. `iCloud.com.yourcompany.trackfree`.
   - Enable iCloud on the App ID and assign the container to it.
2. In Xcode:
   - Open Runner, then **Signing & Capabilities**, and add **iCloud**.
   - Tick **iCloud Documents** and select the container.
   - Do the same for macOS if you ship it.
3. Build with the container ID:
   ```sh
   flutter run --dart-define=ICLOUD_CONTAINER_ID=iCloud.com.yourcompany.trackfree
   ```

## 3. Verify on real devices

Automated tests cover the merge, the sync engine (including a two-device convergence test), the Drive REST client and the controller. They use fakes. Before a release, check with two physical devices:

- [ ] Device A turns sync on. Its data appears on device B after B turns sync on.
- [ ] A checks off a habit and B un-checks the same day. Both end up with the later action.
- [ ] Deleting a habit on A removes it on B.
- [ ] Airplane mode: the app works normally, and the next sync catches up.
- [ ] Revoke the app's access in the Google account settings: the Sync tab shows **Reconnect**.

## Not included yet

- **True background sync** (sync while the app is closed). It would need a background-task plugin, and launch, resume and debounced sync cover normal use.
- **Web.** Google Sign-In on the web needs a rendered sign-in button, and iCloud isn't available there.
