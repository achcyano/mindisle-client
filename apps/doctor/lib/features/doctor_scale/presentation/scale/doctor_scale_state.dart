import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

final class DoctorScaleState {
  const DoctorScaleState({
    this.isLoading = false,
    this.trends = const <DoctorScaleTrendPoint>[],
    this.report,
    this.errorMessage,
  });

  final bool isLoading;
  final List<DoctorScaleTrendPoint> trends;
  final DoctorAssessmentReport? report;
  final String? errorMessage;

  DoctorScaleState copyWith({
    bool? isLoading,
    List<DoctorScaleTrendPoint>? trends,
    Object? report = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorScaleState(
      isLoading: isLoading ?? this.isLoading,
      trends: trends ?? this.trends,
      report: identical(report, _sentinel) ? this.report : report as DoctorAssessmentReport?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
