import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';

final class DoctorMonitorState {
  const DoctorMonitorState({
    this.isLoading = false,
    this.summary = const <SideEffectSummaryItem>[],
    this.weightTrend = const <WeightTrendPoint>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<SideEffectSummaryItem> summary;
  final List<WeightTrendPoint> weightTrend;
  final String? errorMessage;

  DoctorMonitorState copyWith({
    bool? isLoading,
    List<SideEffectSummaryItem>? summary,
    List<WeightTrendPoint>? weightTrend,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorMonitorState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      weightTrend: weightTrend ?? this.weightTrend,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
