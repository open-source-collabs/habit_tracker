# Changelog

All notable changes to Track Free are documented in this file.

## [1.0.0+4] - 2026-10-31

### Added
- In-app review prompts and update prompts to encourage store ratings and keep users on the latest build.
- Vercel-ready privacy policy web app, published alongside updated docs.

### Changed
- Migrated to `flutter_riverpod` 3.4.3.

## [1.0.0+2] - Earlier release

### Added
- Core habit tracking: creation, completion, streaks, and reminders.
- Bento-style dashboard with mobile and desktop layouts.
- Dynamic theming system with customizable accents and design-system widgets (buttons, dialogs, switches, etc.).
- SQLite-backed local persistence with DAOs and schema migrations.
- Reliable on-device reminders via local notifications.
- Cloud backup/sync through the user's own Google Drive or iCloud.
- Home-screen widget support with widget settings and add-widget flow.
- Track Free branding, onboarding flow, splash screen, and settings screens.
- App routing and navigation constants.
- Android `targetSdk` updated to 36.

### Changed
- Centralized ScreenUtil scaling on mobile design units for consistent responsive layout.
- Refactored to feature-first architecture with strict lints and design-system compliance.
