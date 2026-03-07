import 'package:app_core/app_core.dart';
import 'package:patient/features/medication/data/models/medication_models.dart';
import 'package:patient/features/medication/data/remote/medication_api.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';
import 'package:patient/features/medication/domain/repositories/medication_repository.dart';

final class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final MedicationApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<MedicationListResult>> fetchMedications({
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) {
    return _executor.run(
      () => _api.listMedications(
        limit: limit,
        cursor: cursor,
        onlyActive: onlyActive,
      ),
      _decodeListResult,
    );
  }

  @override
  Future<Result<MedicationRecord>> createMedication(
    UpsertMedicationPayload payload,
  ) {
    final request = UpsertMedicationRequestDto.fromDomain(payload);
    return _executor.run(
      () => _api.createMedication(request),
      _decodeMedicationRecord,
    );
  }

  @override
  Future<Result<MedicationRecord>> updateMedication({
    required int medicationId,
    required UpsertMedicationPayload payload,
  }) {
    final request = UpsertMedicationRequestDto.fromDomain(payload);
    return _executor.run(
      () => _api.updateMedication(medicationId: medicationId, request: request),
      _decodeMedicationRecord,
    );
  }

  @override
  Future<Result<bool>> deleteMedication({required int medicationId}) {
    return _executor.runNoData(
      () => _api.deleteMedication(medicationId: medicationId),
    );
  }

  MedicationListResult _decodeListResult(Object? rawData) {
    if (rawData is Map) {
      return MedicationListResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('返回数据格式错误');
  }

  MedicationRecord _decodeMedicationRecord(Object? rawData) {
    if (rawData is Map) {
      return MedicationRecordDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('返回数据格式错误');
  }
}
