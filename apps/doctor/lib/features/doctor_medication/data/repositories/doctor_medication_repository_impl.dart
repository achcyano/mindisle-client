import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_medication/data/models/doctor_medication_models.dart';
import 'package:doctor/features/doctor_medication/data/remote/doctor_medication_api.dart';
import 'package:doctor/features/doctor_medication/domain/repositories/doctor_medication_repository.dart';
import 'package:models/models.dart';

final class DoctorMedicationRepositoryImpl
    implements DoctorMedicationRepository {
  DoctorMedicationRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorMedicationApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<MedicationListResult>> fetchMedications({
    required int patientUserId,
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) {
    return _executor.run(
      () => _api.fetchMedications(
        patientUserId: patientUserId,
        limit: limit,
        cursor: cursor,
        onlyActive: onlyActive,
      ),
      decodeMedicationList,
    );
  }

  @override
  Future<Result<MedicationRecord>> createMedication({
    required int patientUserId,
    required UpsertMedicationPayload payload,
  }) {
    return _executor.run(
      () => _api.createMedication(
        patientUserId: patientUserId,
        request: upsertMedicationPayloadToJson(payload),
      ),
      decodeMedicationRecord,
    );
  }

  @override
  Future<Result<MedicationRecord>> updateMedication({
    required int patientUserId,
    required int medicationId,
    required UpsertMedicationPayload payload,
  }) {
    return _executor.run(
      () => _api.updateMedication(
        patientUserId: patientUserId,
        medicationId: medicationId,
        request: upsertMedicationPayloadToJson(payload),
      ),
      decodeMedicationRecord,
    );
  }

  @override
  Future<Result<void>> deleteMedication({
    required int patientUserId,
    required int medicationId,
  }) async {
    final result = await _executor.runNoData(
      () => _api.deleteMedication(
        patientUserId: patientUserId,
        medicationId: medicationId,
      ),
    );
    return switch (result) {
      Success<bool>() => const Success(null),
      Failure<bool>(error: final error) => Failure(error),
    };
  }
}
