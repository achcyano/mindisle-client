import 'package:patient/core/result/result.dart';
import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';
import 'package:patient/features/side_effect/domain/repositories/side_effect_repository.dart';

final class CreateSideEffectUseCase {
  const CreateSideEffectUseCase(this._repository);

  final SideEffectRepository _repository;

  Future<Result<SideEffectRecord>> execute(CreateSideEffectPayload payload) {
    return _repository.createSideEffect(payload);
  }
}

final class FetchSideEffectsUseCase {
  const FetchSideEffectsUseCase(this._repository);

  final SideEffectRepository _repository;

  Future<Result<SideEffectListResult>> execute({
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchSideEffects(limit: limit, cursor: cursor);
  }
}
