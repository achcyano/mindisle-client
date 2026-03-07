import 'package:patient/core/result/result.dart';
import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';

abstract interface class SideEffectRepository {
  Future<Result<SideEffectRecord>> createSideEffect(CreateSideEffectPayload payload);

  Future<Result<SideEffectListResult>> fetchSideEffects({
    int limit = 20,
    String? cursor,
  });
}
