import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';

typedef DoctorMonitorState = AsyncState<DoctorMonitorData>;

final class DoctorMonitorData {
  const DoctorMonitorData({
    this.summary = const <SideEffectSummaryItem>[],
    this.weightTrend = const <WeightTrendPoint>[],
  });

  final List<SideEffectSummaryItem> summary;
  final List<WeightTrendPoint> weightTrend;

  DoctorMonitorData copyWith({
    List<SideEffectSummaryItem>? summary,
    List<WeightTrendPoint>? weightTrend,
  }) {
    return DoctorMonitorData(
      summary: summary ?? this.summary,
      weightTrend: weightTrend ?? this.weightTrend,
    );
  }
}
