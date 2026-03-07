import 'package:app_core/app_core.dart';
import 'package:models/models.dart';

abstract interface class DoctorMedicationRepository {
  Future<Result<MedicationListResult>> fetchMedications({
    required int patientUserId,
    int limit,
    String? cursor,
    bool? onlyActive,
  });

  Future<Result<MedicationRecord>> createMedication({
    required int patientUserId,
    required UpsertMedicationPayload payload,
  });

  Future<Result<MedicationRecord>> updateMedication({
    required int patientUserId,
    required int medicationId,
    required UpsertMedicationPayload payload,
  });

  Future<Result<void>> deleteMedication({
    required int patientUserId,
    required int medicationId,
  });
}

