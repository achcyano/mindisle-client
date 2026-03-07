import 'package:app_core/app_core.dart';
import 'package:patient/features/side_effect/data/models/side_effect_models.dart';
import 'package:patient/features/side_effect/data/remote/side_effect_api.dart';
import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';
import 'package:patient/features/side_effect/domain/repositories/side_effect_repository.dart';

final class SideEffectRepositoryImpl implements SideEffectRepository {
  SideEffectRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final SideEffectApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<SideEffectRecord>> createSideEffect(
    CreateSideEffectPayload payload,
  ) {
    final request = CreateSideEffectRequestDto.fromDomain(payload);
    return _executor.run(
      () => _api.createSideEffect(request),
      _decodeRecord,
    );
  }

  @override
  Future<Result<SideEffectListResult>> fetchSideEffects({
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.listSideEffects(limit: limit, cursor: cursor),
      _decodeList,
    );
  }

  SideEffectRecord _decodeRecord(Object? rawData) {
    if (rawData is Map) {
      return SideEffectRecordDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('Invalid side effect payload');
  }

  SideEffectListResult _decodeList(Object? rawData) {
    if (rawData is Map) {
      return SideEffectListResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('Invalid side effect list payload');
  }
}
