import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../features/themes/data/models/dynamic_theme_model.dart';
import '../database_schema.dart';

/// Data Access Object for custom and built-in user themes.
class ThemeDao {
  const ThemeDao();

  /// Retrieves all persisted user themes.
  Future<List<UserThemeModel>> getAllThemes(DatabaseExecutor executor) async {
    final rows = await executor.query(
      DatabaseSchema.tableUserThemes,
      orderBy: '${DatabaseSchema.colThemeIsBuiltIn} DESC, ${DatabaseSchema.colThemeName} ASC',
    );

    return rows.map((row) {
      final accentPaletteJson =
          row[DatabaseSchema.colThemeAccentPaletteHex] as String? ?? '[]';
      final List<String> accentPaletteHex =
          (jsonDecode(accentPaletteJson) as List<dynamic>)
              .map((e) => e as String)
              .toList();

      final lastModifiedStr =
          row[DatabaseSchema.colThemeLastModifiedAt] as String?;

      return UserThemeModel(
        id: row[DatabaseSchema.colThemeId] as String,
        name: row[DatabaseSchema.colThemeName] as String,
        fontFamily: row[DatabaseSchema.colThemeFontFamily] as String,
        scaffoldBgHex: row[DatabaseSchema.colThemeScaffoldBgHex] as String,
        cardBgHex: row[DatabaseSchema.colThemeCardBgHex] as String,
        cardBorderHex: row[DatabaseSchema.colThemeCardBorderHex] as String,
        textPrimaryHex: row[DatabaseSchema.colThemeTextPrimaryHex] as String,
        textSecondaryHex:
            row[DatabaseSchema.colThemeTextSecondaryHex] as String? ?? '#94A3B8',
        accentPaletteHex: accentPaletteHex,
        isBuiltIn: (row[DatabaseSchema.colThemeIsBuiltIn] as int? ?? 0) == 1,
        lastModifiedAt: lastModifiedStr != null
            ? DateTime.tryParse(lastModifiedStr)
            : null,
      );
    }).toList();
  }

  /// Synchronizes user themes, removing any deleted custom themes.
  Future<void> syncThemes(
    DatabaseExecutor executor,
    List<UserThemeModel> themes,
  ) async {
    final existingRows = await executor.query(
      DatabaseSchema.tableUserThemes,
      columns: [DatabaseSchema.colThemeId],
    );
    final existingIds = existingRows
        .map((r) => r[DatabaseSchema.colThemeId] as String)
        .toSet();

    final currentIds = themes.map((t) => t.id).toSet();
    final idsToDelete = existingIds.difference(currentIds);

    for (final id in idsToDelete) {
      await deleteTheme(executor, id);
    }

    for (final theme in themes) {
      await upsertTheme(executor, theme);
    }
  }

  /// Upserts a theme row.
  Future<void> upsertTheme(
    DatabaseExecutor executor,
    UserThemeModel theme,
  ) async {
    await executor.insert(
      DatabaseSchema.tableUserThemes,
      {
        DatabaseSchema.colThemeId: theme.id,
        DatabaseSchema.colThemeName: theme.name,
        DatabaseSchema.colThemeFontFamily: theme.fontFamily,
        DatabaseSchema.colThemeScaffoldBgHex: theme.scaffoldBgHex,
        DatabaseSchema.colThemeCardBgHex: theme.cardBgHex,
        DatabaseSchema.colThemeCardBorderHex: theme.cardBorderHex,
        DatabaseSchema.colThemeTextPrimaryHex: theme.textPrimaryHex,
        DatabaseSchema.colThemeTextSecondaryHex: theme.textSecondaryHex,
        DatabaseSchema.colThemeAccentPaletteHex:
            jsonEncode(theme.accentPaletteHex),
        DatabaseSchema.colThemeIsBuiltIn: theme.isBuiltIn ? 1 : 0,
        DatabaseSchema.colThemeLastModifiedAt:
            theme.lastModifiedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a custom theme by [id].
  Future<void> deleteTheme(DatabaseExecutor executor, String id) async {
    await executor.delete(
      DatabaseSchema.tableUserThemes,
      where: '${DatabaseSchema.colThemeId} = ?',
      whereArgs: [id],
    );
  }

  /// Truncates user themes.
  Future<void> clear(DatabaseExecutor executor) async {
    await executor.delete(DatabaseSchema.tableUserThemes);
  }
}
