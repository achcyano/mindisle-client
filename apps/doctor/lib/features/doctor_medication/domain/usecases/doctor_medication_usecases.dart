import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_medication/domain/repositories/doctor_medication_repository.dart';
import 'package:models/models.dart';

final class FetchDoctorMedicationsUseCase {
  const FetchDoctorMedicationsUseCase(this._repository);

  final DoctorMedicationRepository _repository;

  Future<Result<MedicationListResult>> execute({
    required int patientUserId,
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) {
    return _repository.fetchMedications(
      patientUserId: patientUserId,
      limit: limit,
      cursor: cursor,
      onlyActive: onlyActive,
    );
  }
}

final class CreateDoctorMedicationUseCase {
  const CreateDoctorMedicationUseCase(this._repository);

  final DoctorMedicationRepository _repository;

  Future<Result<MedicationRecord>> execute({
    required int patientUserId,
    required UpsertMedicationPayload payload,
  }) {
    return _repository.createMedication(
      patientUserId: patientUserId,
      payload: payload,
    );
  }
}

final class UpdateDoctorMedicationUseCase {
  const UpdateDoctorMedicationUseCase(this._repository);

  final DoctorMedicationRepository _repository;

  Future<Result<MedicationRecord>> execute({
    required int patientUserId,
    required int medicationId,
    required UpsertMedicationPayload payload,
  }) {
    return _repository.updateMedication(
      patientUserId: patientUserId,
      medicationId: medicationId,
      payload: payload,
    );
  }
}

final class DeleteDoctorMedicationUseCase {
  const DeleteDoctorMedicationUseCase(this._repository);

  final DoctorMedicationRepository _repository;

  Future<Result<void>> execute({
    required int patientUserId,
    required int medicationId,
  }) async {
    final result = await _repository.deleteMedication(
      patientUserId: patientUserId,
      medicationId: medicationId,
    );
    return result;
  }
}
