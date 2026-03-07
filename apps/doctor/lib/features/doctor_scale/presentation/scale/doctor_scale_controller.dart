import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/presentation/providers/doctor_scale_providers.dart';
import 'package:doctor/features/doctor_scale/presentation/scale/doctor_scale_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorScaleControllerProvider =
    StateNotifierProvider<DoctorScaleController, DoctorScaleState>((ref) {
  return DoctorScaleController(ref);
});

final class DoctorScaleController extends StateNotifier<DoctorScaleState> {
  DoctorScaleController(this._ref) : super(const DoctorScaleState());

  final Ref _ref;

  Future<void> loadTrends({required int patientUserId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(fetchDoctorScaleTrendsUseCaseProvider).execute(
          patientUserId: patientUserId,
        );
    switch (result) {
      case Success<List<DoctorScaleTrendPoint>>(data: final data):
        state = state.copyWith(isLoading: false, trends: data);
      case Failure<List<DoctorScaleTrendPoint>>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<String?> generateReport({required int patientUserId, int? days}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(generateDoctorAssessmentReportUseCaseProvider).execute(
          patientUserId: patientUserId,
          days: days,
        );
    switch (result) {
      case Success<DoctorAssessmentReport>(data: final data):
        state = state.copyWith(isLoading: false, report: data);
        return null;
      case Failure<DoctorAssessmentReport>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return error.message;
    }
  }
}
