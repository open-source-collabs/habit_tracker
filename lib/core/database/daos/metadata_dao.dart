import 'package:sqflite/sqflite.dart';

import '../database_schema.dart';

/// Data Access Object for global application metadata and deletion tombstones.
class MetadataDao {
  const MetadataDao();

  /// Retrieves all key-value pairs from the metadata table.
  Future<Map<String, String>> getAllMetadata(DatabaseExecutor executor) async {
    final rows = await executor.query(DatabaseSchema.tableAppMetadata);
    final result = <String, String>{};
    for (final row in rows) {
      result[row[DatabaseSchema.colMetaKey] as String] =
          row[DatabaseSchema.colMetaValue] as String;
    }
    return result;
  }

  /// Sets or updates a single metadata key-value pair.
  Future<void> setMetadata(
    DatabaseExecutor executor,
    String key,
    String value,
  ) async {
    await executor.insert(
      DatabaseSchema.tableAppMetadata,
      {
        DatabaseSchema.colMetaKey: key,
        DatabaseSchema.colMetaValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch updates metadata key-value pairs.
  Future<void> setAllMetadata(
    DatabaseExecutor executor,
    Map<String, String> entries,
  ) async {
    for (final entry in entries.entries) {
      await setMetadata(executor, entry.key, entry.value);
    }
  }

  /// Retrieves deletion tombstones for a specific entity type ('habit' or 'theme').
  Future<Map<String, DateTime>> getTombstones(
    DatabaseExecutor executor,
    String entityType,
  ) async {
    final rows = await executor.query(
      DatabaseSchema.tableTombstones,
      where: '${DatabaseSchema.colTombstoneEntityType} = ?',
      whereArgs: [entityType],
    );

    final result = <String, DateTime>{};
    for (final row in rows) {
      final id = row[DatabaseSchema.colTombstoneEntityId] as String;
      final dateStr = row[DatabaseSchema.colTombstoneDeletedAt] as String;
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        result[id] = parsed;
      }
    }
    return result;
  }

  /// Synchronizes tombstones for a specific entity type ('habit' or 'theme').
  Future<void> syncTombstones(
    DatabaseExecutor executor,
    String entityType,
    Map<String, DateTime> tombstones,
  ) async {
    // Delete existing tombstones for this entity type
    await executor.delete(
      DatabaseSchema.tableTombstones,
      where: '${DatabaseSchema.colTombstoneEntityType} = ?',
      whereArgs: [entityType],
    );

    for (final entry in tombstones.entries) {
      await executor.insert(
        DatabaseSchema.tableTombstones,
        {
          DatabaseSchema.colTombstoneEntityType: entityType,
          DatabaseSchema.colTombstoneEntityId: entry.key,
          DatabaseSchema.colTombstoneDeletedAt: entry.value.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Clears metadata and tombstones.
  Future<void> clear(DatabaseExecutor executor) async {
    await executor.delete(DatabaseSchema.tableTombstones);
    await executor.delete(DatabaseSchema.tableAppMetadata);
  }
}
