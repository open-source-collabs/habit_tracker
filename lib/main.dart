import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.initializePlatform();
  runApp(
    const ProviderScope(
      child: HabitTrackerApp(),
    ),
  );
}
