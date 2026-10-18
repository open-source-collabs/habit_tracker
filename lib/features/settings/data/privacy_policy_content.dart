/// The privacy policy shown in Settings. Keep in sync with
/// `docs/privacy_policy.md` / `docs/privacy_policy.html` (the hosted copy
/// the store listings link to).
abstract final class PrivacyPolicyContent {
  static const String effectiveDate = '18 October 2026';

  static const List<({String heading, String body})> sections = [
    (
      heading: 'Summary',
      body: 'Track Free is a habit tracker that keeps your data on your '
          'device. There is no Track Free account, no server, no '
          'advertising and no analytics. We (the developer) never receive '
          'your habits or any personal data.',
    ),
    (
      heading: 'Data stored on your device',
      body: 'Your habits, check-in history, reminder times, themes, the '
          'optional display name you enter, notification preferences and a '
          'random installation ID (used only to tell your own devices apart '
          'during sync) are stored locally in the app\'s private storage. '
          'Automatic backups of this data are also kept on the device.',
    ),
    (
      heading: 'Optional cloud sync',
      body: 'If you turn on sync, a copy of the same data is saved to your '
          'own cloud storage: the hidden app-data folder of your Google '
          'Drive (Android) or your private iCloud container (Apple devices). '
          'For Google Drive, the app asks only for access to its own app '
          'folder — it cannot see your other files — and shows the email '
          'address of the signed-in account so you know which account is '
          'used. This data is transferred directly between your device and '
          'Google or Apple over an encrypted connection and is governed by '
          'their privacy policies. It is never sent to us.',
    ),
    (
      heading: 'Reminders',
      body: 'Reminders are scheduled locally by your device\'s operating '
          'system. No notification service or push server is involved.',
    ),
    (
      heading: 'Permissions',
      body: 'Notifications: to show the reminders you set. Run at startup: '
          'to restore scheduled reminders after your phone restarts. '
          'Internet: used only for optional cloud sync.',
    ),
    (
      heading: 'Sharing',
      body: 'We do not sell, share or transfer your data to anyone. The app '
          'contains no third-party analytics, advertising or tracking SDKs.',
    ),
    (
      heading: 'Deleting your data',
      body: 'Settings → Delete all data removes everything from this device; '
          'uninstalling the app does too. To remove the cloud copy, turn off '
          'sync and delete Track Free\'s data in Google Drive (Settings → '
          'Manage apps) or in your iCloud storage settings.',
    ),
    (
      heading: 'Children',
      body: 'Track Free is not directed at children under 13 and does not '
          'knowingly collect information from them.',
    ),
    (
      heading: 'Changes',
      body: 'If this policy changes, the new version will be published at '
          'the same address and in the app, with a new effective date.',
    ),
  ];
}
