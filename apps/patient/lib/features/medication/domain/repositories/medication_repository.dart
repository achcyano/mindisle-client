import 'package:patient/core/result/result.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';

abstract interface class MedicationRepository {
  Future<Result<MedicationListResult>> fetchMedications({
    int limit,
    String? cursor,
    bool? onlyActive,
  });

  Future<Result<MedicationRecord>> createMedication(
    UpsertMedicationPayload payload,
  );

  Future<Result<MedicationRecord>> updateMedication({
    required int medicationId,
    required UpsertMedicationPayload payload,
  });

  Future<Result<bool>> deleteMedication({
    required int medicationId,
  });
}
