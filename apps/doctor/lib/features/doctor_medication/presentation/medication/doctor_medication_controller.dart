import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_medication/presentation/medication/doctor_medication_state.dart';
import 'package:doctor/features/doctor_medication/presentation/providers/doctor_medication_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

final doctorMedicationControllerProvider =
    StateNotifierProvider<DoctorMedicationController, DoctorMedicationState>((ref) {
  return DoctorMedicationController(ref);
});

final class DoctorMedicationController extends StateNotifier<DoctorMedicationState> {
  DoctorMedicationController(this._ref) : super(const DoctorMedicationState());

  final Ref _ref;

  Future<void> refresh({required int patientUserId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(fetchDoctorMedicationsUseCaseProvider).execute(
          patientUserId: patientUserId,
          limit: 200,
        );
    switch (result) {
      case Success<MedicationListResult>(data: final data):
        state = state.copyWith(isLoading: false, items: data.items);
      case Failure<MedicationListResult>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<String?> create({
    required int patientUserId,
    required UpsertMedicationPayload payload,
  }) async {
    final result = await _ref.read(createDoctorMedicationUseCaseProvider).execute(
          patientUserId: patientUserId,
          payload: payload,
        );
    switch (result) {
      case Success<MedicationRecord>(data: final data):
        state = state.copyWith(items: [data, ...state.items]);
        return null;
      case Failure<MedicationRecord>(error: final error):
        state = state.copyWith(errorMessage: error.message);
        return error.message;
    }
  }

  Future<String?> remove({
    required int patientUserId,
    required int medicationId,
  }) async {
    final result = await _ref.read(deleteDoctorMedicationUseCaseProvider).execute(
          patientUserId: patientUserId,
          medicationId: medicationId,
        );
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          items: state.items.where((e) => e.medicationId != medicationId).toList(),
        );
        return null;
      case Failure<void>(error: final error):
        state = state.copyWith(errorMessage: error.message);
        return error.message;
    }
  }
}

