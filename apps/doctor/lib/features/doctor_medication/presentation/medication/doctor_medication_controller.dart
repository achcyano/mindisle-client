import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_medication/presentation/medication/doctor_medication_state.dart';
import 'package:doctor/features/doctor_medication/presentation/providers/doctor_medication_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

final doctorMedicationControllerProvider =
    StateNotifierProvider<DoctorMedicationController, DoctorMedicationState>((
      ref,
    ) {
      return DoctorMedicationController(ref);
    });

final class DoctorMedicationController
    extends AsyncController<DoctorMedicationData> {
  DoctorMedicationController(this._ref)
    : super(
        const AsyncState<DoctorMedicationData>(data: DoctorMedicationData()),
      );

  final Ref _ref;

  Future<void> refresh({required int patientUserId}) async {
    await runAction<MedicationListResult>(
      request: () => _ref
          .read(fetchDoctorMedicationsUseCaseProvider)
          .execute(patientUserId: patientUserId, limit: 200),
      onSuccess: (current, data) => current.copyWith(items: data.items),
    );
  }

  Future<String?> create({
    required int patientUserId,
    required UpsertMedicationPayload payload,
  }) {
    return runAction<MedicationRecord>(
      request: () => _ref
          .read(createDoctorMedicationUseCaseProvider)
          .execute(patientUserId: patientUserId, payload: payload),
      onSuccess: (current, record) =>
          current.copyWith(items: <MedicationRecord>[record, ...current.items]),
      withLoading: false,
    );
  }

  Future<String?> remove({
    required int patientUserId,
    required int medicationId,
  }) {
    return runAction<void>(
      request: () => _ref
          .read(deleteDoctorMedicationUseCaseProvider)
          .execute(patientUserId: patientUserId, medicationId: medicationId),
      onSuccess: (current, _) => current.copyWith(
        items: current.items
            .where((e) => e.medicationId != medicationId)
            .toList(),
      ),
      withLoading: false,
    );
  }
}
