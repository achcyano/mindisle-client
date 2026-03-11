import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

typedef DoctorScaleState = AsyncState<DoctorScaleData>;

final class DoctorScaleData {
  const DoctorScaleData({
    this.trends = const <DoctorScaleTrendPoint>[],
    this.report,
  });

  final List<DoctorScaleTrendPoint> trends;
  final DoctorAssessmentReport? report;

  DoctorScaleData copyWith({
    List<DoctorScaleTrendPoint>? trends,
    Object? report = asyncStateNoChange,
  }) {
    return DoctorScaleData(
      trends: trends ?? this.trends,
      report: identical(report, asyncStateNoChange)
          ? this.report
          : report as DoctorAssessmentReport?,
    );
  }
}
