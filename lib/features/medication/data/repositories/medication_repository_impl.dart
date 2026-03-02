import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/medication/data/models/medication_models.dart';
import 'package:mindisle_client/features/medication/data/remote/medication_api.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/features/medication/domain/repositories/medication_repository.dart';

final class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._api);

  final MedicationApi _api;

  @override
  Future<Result<MedicationListResult>> fetchMedications({
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) {
    return _run(
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
    return _run(
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
    return _run(
      () => _api.updateMedication(medicationId: medicationId, request: request),
      _decodeMedicationRecord,
    );
  }

  @override
  Future<Result<bool>> deleteMedication({required int medicationId}) {
    return _runNoData(() => _api.deleteMedication(medicationId: medicationId));
  }

  Future<Result<T>> _run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) decodeData,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<T>.fromJson(json, decodeData);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }

      final data = envelope.data;
      if (data == null) {
        return Failure(
          mapServerCodeToAppError(code: 50000, message: '响应数据为空'),
        );
      }

      return Success(data);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  Future<Result<bool>> _runNoData(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<Object?>.fromJson(json, (raw) => raw);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }
      return const Success(true);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  MedicationListResult _decodeListResult(Object? rawData) {
    if (rawData is Map) {
      return MedicationListResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('用药列表格式错误');
  }

  MedicationRecord _decodeMedicationRecord(Object? rawData) {
    if (rawData is Map) {
      return MedicationRecordDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('用药记录格式错误');
  }
}
