import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/presentation/providers/doctor_scale_providers.dart';
import 'package:doctor/features/doctor_scale/presentation/scale/doctor_scale_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorScaleControllerProvider =
    StateNotifierProvider<DoctorScaleController, DoctorScaleState>((ref) {
      return DoctorScaleController(ref);
    });

final class DoctorScaleController extends AsyncController<DoctorScaleData> {
  DoctorScaleController(this._ref)
    : super(const AsyncState<DoctorScaleData>(data: DoctorScaleData()));

  final Ref _ref;

  Future<void> loadTrends({required int patientUserId}) async {
    await runAction<List<DoctorScaleTrendPoint>>(
      request: () => _ref
          .read(fetchDoctorScaleTrendsUseCaseProvider)
          .execute(patientUserId: patientUserId),
      onSuccess: (current, trends) => current.copyWith(trends: trends),
    );
  }

  Future<String?> generateReport({required int patientUserId, int? days}) {
    return runAction<DoctorAssessmentReport>(
      request: () => _ref
          .read(generateDoctorAssessmentReportUseCaseProvider)
          .execute(patientUserId: patientUserId, days: days),
      onSuccess: (current, report) => current.copyWith(report: report),
    );
  }
}
