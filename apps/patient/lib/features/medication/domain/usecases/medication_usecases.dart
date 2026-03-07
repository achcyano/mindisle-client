import 'package:patient/core/result/result.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';
import 'package:patient/features/medication/domain/repositories/medication_repository.dart';

final class FetchMedicationsUseCase {
  const FetchMedicationsUseCase(this._repository);

  final MedicationRepository _repository;

  Future<Result<MedicationListResult>> execute({
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) {
    return _repository.fetchMedications(
      limit: limit,
      cursor: cursor,
      onlyActive: onlyActive,
    );
  }
}

final class CreateMedicationUseCase {
  const CreateMedicationUseCase(this._repository);

  final MedicationRepository _repository;

  Future<Result<MedicationRecord>> execute(UpsertMedicationPayload payload) {
    return _repository.createMedication(payload);
  }
}

final class UpdateMedicationUseCase {
  const UpdateMedicationUseCase(this._repository);

  final MedicationRepository _repository;

  Future<Result<MedicationRecord>> execute({
    required int medicationId,
    required UpsertMedicationPayload payload,
  }) {
    return _repository.updateMedication(
      medicationId: medicationId,
      payload: payload,
    );
  }
}

final class DeleteMedicationUseCase {
  const DeleteMedicationUseCase(this._repository);

  final MedicationRepository _repository;

  Future<Result<bool>> execute({
    required int medicationId,
  }) {
    return _repository.deleteMedication(medicationId: medicationId);
  }
}
