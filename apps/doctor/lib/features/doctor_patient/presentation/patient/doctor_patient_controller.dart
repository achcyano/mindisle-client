import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_state.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorPatientControllerProvider =
    StateNotifierProvider<DoctorPatientController, DoctorPatientState>((ref) {
  return DoctorPatientController(ref);
});

final class DoctorPatientController extends StateNotifier<DoctorPatientState> {
  DoctorPatientController(this._ref) : super(const DoctorPatientState());

  final Ref _ref;

  Future<void> refresh({String? keyword, bool? abnormalOnly}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(fetchDoctorPatientsUseCaseProvider).execute(
          limit: 50,
          keyword: keyword,
          abnormalOnly: abnormalOnly,
        );

    switch (result) {
      case Success<DoctorPatientListResult>(data: final data):
        state = state.copyWith(isLoading: false, items: data.items);
      case Failure<DoctorPatientListResult>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<String?> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) async {
    final result = await _ref.read(updateDoctorPatientGroupingUseCaseProvider).execute(
          patientUserId: patientUserId,
          payload: payload,
        );
    return switch (result) {
      Success<DoctorPatientGrouping>() => null,
      Failure<DoctorPatientGrouping>(error: final error) => error.message,
    };
  }
}
