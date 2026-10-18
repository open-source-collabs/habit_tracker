import 'habit_storage.dart';
import 'habit_storage_stub.dart'
    if (dart.library.io) 'sqflite_habit_storage.dart'
    if (dart.library.js_interop) 'web_habit_storage.dart';

/// Factory providing transparent cross-platform instantiation of [HabitStorage].
abstract final class HabitStorageFactory {
  /// Instantiates the appropriate [HabitStorage] engine for the current platform.
  static HabitStorage createStorage() => createPlatformHabitStorage();
}
