import '../../../themes/data/models/app_payload_model.dart';

abstract interface class HabitStorage {
  Future<AppPayloadModel?> loadPayload();

  Future<void> savePayload(AppPayloadModel payload);

  Future<List<String>> listBackups();

  Future<AppPayloadModel?> restoreBackup(String backupName);

  Future<void> clear();
}
