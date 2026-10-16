import '../../../themes/data/models/app_payload_model.dart';

abstract interface class HabitStorage {
  /// Loads the persisted payload.
  ///
  /// Returns `null` only when no data has ever been written (true first run).
  /// Throws [CorruptPayloadException] when data exists but neither the primary
  /// record nor any backup can be parsed — callers must not treat this as a
  /// first run, otherwise the next save would rotate the damaged data out of
  /// the backups.
  Future<AppPayloadModel?> loadPayload();

  Future<void> savePayload(AppPayloadModel payload);

  Future<List<String>> listBackups();

  Future<AppPayloadModel?> restoreBackup(String backupName);

  Future<void> clear();
}

/// Thrown when stored data exists but cannot be read from the primary record
/// or any rolling backup. A copy of the damaged primary record is preserved
/// before this is thrown.
class CorruptPayloadException implements Exception {
  final Object? cause;

  const CorruptPayloadException([this.cause]);

  @override
  String toString() =>
      'CorruptPayloadException: stored data could not be read'
      '${cause != null ? ' ($cause)' : ''}';
}
