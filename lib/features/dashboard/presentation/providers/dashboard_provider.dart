import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active dashboard bottom navigation tab index (0: Today, 1: Analytics, 2: Themes, 3: Sync).
final selectedDashboardTabProvider = StateProvider<int>((ref) => 0);
