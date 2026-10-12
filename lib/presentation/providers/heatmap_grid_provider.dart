import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameter object identifying a HeatmapGrid instance and its initial day range.
class HeatmapRangeParams {
  final String id;
  final int initialDays;

  const HeatmapRangeParams({
    required this.id,
    required this.initialDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapRangeParams &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Auto-disposing notifier managing the active display range (30, 60, or 90 days) for a heatmap.
class HeatmapRangeDaysNotifier
    extends AutoDisposeFamilyNotifier<int, HeatmapRangeParams> {
  @override
  int build(HeatmapRangeParams arg) {
    return arg.initialDays.clamp(30, 90);
  }

  void setDays(int days) {
    state = days.clamp(30, 90);
  }
}

/// Provider exposing the reactive selected range days for a heatmap grid instance.
final heatmapRangeDaysProvider = AutoDisposeNotifierProviderFamily<
    HeatmapRangeDaysNotifier, int, HeatmapRangeParams>(
  HeatmapRangeDaysNotifier.new,
);
