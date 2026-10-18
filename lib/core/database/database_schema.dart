/// SQLite schema constants and DDL statements for the Habit Tracker application.
abstract final class DatabaseSchema {
  static const int version = 1;
  static const String databaseName = 'habit_tracker.db';

  // --- Table Names ---
  static const String tableHabits = 'habits';
  static const String tableCheckIns = 'check_ins';
  static const String tableUserThemes = 'user_themes';
  static const String tableAppMetadata = 'app_metadata';
  static const String tableTombstones = 'tombstones';
  static const String tableNotificationSettings = 'notification_settings';
  static const String tableBackups = 'backups';

  // --- Habits Columns ---
  static const String colHabitId = 'id';
  static const String colHabitTitle = 'title';
  static const String colHabitSubtitle = 'subtitle';
  static const String colHabitFrequencyType = 'frequency_type';
  static const String colHabitDaysOfWeek = 'frequency_days_of_week';
  static const String colHabitTargetTimesPerWeek = 'frequency_target_times_per_week';
  static const String colHabitRoutineGroup = 'routine_group';
  static const String colHabitAccentIndex = 'accent_index';
  static const String colHabitCreatedAt = 'created_at';
  static const String colHabitIsArchived = 'is_archived';
  static const String colHabitEmoji = 'emoji';
  static const String colHabitCustomColorValue = 'custom_color_value';
  static const String colHabitIconCode = 'icon_code';
  static const String colHabitReminderTime = 'reminder_time';
  static const String colHabitLastModifiedAt = 'last_modified_at';

  // --- Check-Ins Columns ---
  static const String colCheckInHabitId = 'habit_id';
  static const String colCheckInDate = 'date';
  static const String colCheckInCompleted = 'completed';
  static const String colCheckInChangedAt = 'changed_at';

  // --- User Themes Columns ---
  static const String colThemeId = 'id';
  static const String colThemeName = 'name';
  static const String colThemeFontFamily = 'font_family';
  static const String colThemeScaffoldBgHex = 'scaffold_bg_hex';
  static const String colThemeCardBgHex = 'card_bg_hex';
  static const String colThemeCardBorderHex = 'card_border_hex';
  static const String colThemeTextPrimaryHex = 'text_primary_hex';
  static const String colThemeTextSecondaryHex = 'text_secondary_hex';
  static const String colThemeAccentPaletteHex = 'accent_palette_hex';
  static const String colThemeIsBuiltIn = 'is_built_in';
  static const String colThemeLastModifiedAt = 'last_modified_at';

  // --- App Metadata Columns ---
  static const String colMetaKey = 'key';
  static const String colMetaValue = 'value';

  // Metadata Keys
  static const String metaKeySchemaVersion = 'schema_version';
  static const String metaKeyLastModifiedBy = 'last_modified_by';
  static const String metaKeyLastModifiedAt = 'last_modified_at';
  static const String metaKeyActiveThemeId = 'active_theme_id';
  static const String metaKeyDisplayName = 'display_name';

  // --- Tombstones Columns ---
  static const String colTombstoneEntityType = 'entity_type';
  static const String colTombstoneEntityId = 'entity_id';
  static const String colTombstoneDeletedAt = 'deleted_at';

  // --- Notification Settings Columns ---
  static const String colNotificationId = 'id';
  static const String colNotificationSettingsJson = 'settings_json';

  // --- Backups Columns ---
  static const String colBackupName = 'name';
  static const String colBackupPayloadJson = 'payload_json';
  static const String colBackupCreatedAt = 'created_at';

  // --- DDL Create Table Statements ---
  static const String createHabitsTable = '''
    CREATE TABLE $tableHabits (
      $colHabitId TEXT PRIMARY KEY,
      $colHabitTitle TEXT NOT NULL,
      $colHabitSubtitle TEXT NOT NULL DEFAULT '',
      $colHabitFrequencyType TEXT NOT NULL,
      $colHabitDaysOfWeek TEXT NOT NULL DEFAULT '[]',
      $colHabitTargetTimesPerWeek INTEGER NOT NULL DEFAULT 1,
      $colHabitRoutineGroup TEXT NOT NULL DEFAULT 'General',
      $colHabitAccentIndex INTEGER NOT NULL DEFAULT 0,
      $colHabitCreatedAt TEXT NOT NULL,
      $colHabitIsArchived INTEGER NOT NULL DEFAULT 0,
      $colHabitEmoji TEXT,
      $colHabitCustomColorValue INTEGER,
      $colHabitIconCode TEXT,
      $colHabitReminderTime TEXT,
      $colHabitLastModifiedAt TEXT
    );
  ''';

  static const String createCheckInsTable = '''
    CREATE TABLE $tableCheckIns (
      $colCheckInHabitId TEXT NOT NULL,
      $colCheckInDate TEXT NOT NULL,
      $colCheckInCompleted INTEGER NOT NULL DEFAULT 1,
      $colCheckInChangedAt INTEGER NOT NULL,
      PRIMARY KEY ($colCheckInHabitId, $colCheckInDate),
      FOREIGN KEY ($colCheckInHabitId) REFERENCES $tableHabits ($colHabitId) ON DELETE CASCADE
    );
  ''';

  static const String createUserThemesTable = '''
    CREATE TABLE $tableUserThemes (
      $colThemeId TEXT PRIMARY KEY,
      $colThemeName TEXT NOT NULL,
      $colThemeFontFamily TEXT NOT NULL,
      $colThemeScaffoldBgHex TEXT NOT NULL,
      $colThemeCardBgHex TEXT NOT NULL,
      $colThemeCardBorderHex TEXT NOT NULL,
      $colThemeTextPrimaryHex TEXT NOT NULL,
      $colThemeTextSecondaryHex TEXT NOT NULL DEFAULT '#94A3B8',
      $colThemeAccentPaletteHex TEXT NOT NULL,
      $colThemeIsBuiltIn INTEGER NOT NULL DEFAULT 0,
      $colThemeLastModifiedAt TEXT
    );
  ''';

  static const String createAppMetadataTable = '''
    CREATE TABLE $tableAppMetadata (
      $colMetaKey TEXT PRIMARY KEY,
      $colMetaValue TEXT NOT NULL
    );
  ''';

  static const String createTombstonesTable = '''
    CREATE TABLE $tableTombstones (
      $colTombstoneEntityType TEXT NOT NULL,
      $colTombstoneEntityId TEXT NOT NULL,
      $colTombstoneDeletedAt TEXT NOT NULL,
      PRIMARY KEY ($colTombstoneEntityType, $colTombstoneEntityId)
    );
  ''';

  static const String createNotificationSettingsTable = '''
    CREATE TABLE $tableNotificationSettings (
      $colNotificationId INTEGER PRIMARY KEY CHECK ($colNotificationId = 1),
      $colNotificationSettingsJson TEXT NOT NULL
    );
  ''';

  static const String createBackupsTable = '''
    CREATE TABLE $tableBackups (
      $colBackupName TEXT PRIMARY KEY,
      $colBackupPayloadJson TEXT NOT NULL,
      $colBackupCreatedAt TEXT NOT NULL
    );
  ''';

  // --- Indexes ---
  static const List<String> createIndexes = [
    'CREATE INDEX idx_habits_is_archived ON $tableHabits ($colHabitIsArchived);',
    'CREATE INDEX idx_habits_routine_group ON $tableHabits ($colHabitRoutineGroup);',
    'CREATE INDEX idx_check_ins_date ON $tableCheckIns ($colCheckInDate);',
    'CREATE INDEX idx_check_ins_habit_id ON $tableCheckIns ($colCheckInHabitId);',
  ];
}
