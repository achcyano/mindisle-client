import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/features/side_effect/data/remote/side_effect_api.dart';
import 'package:patient/features/side_effect/data/repositories/side_effect_repository_impl.dart';
import 'package:patient/features/side_effect/domain/repositories/side_effect_repository.dart';
import 'package:patient/features/side_effect/domain/usecases/side_effect_usecases.dart';

final sideEffectApiProvider = Provider<SideEffectApi>((ref) {
  return SideEffectApi(ref.watch(appDioProvider));
});

final sideEffectRepositoryProvider = Provider<SideEffectRepository>((ref) {
  return SideEffectRepositoryImpl(ref.watch(sideEffectApiProvider));
});

final createSideEffectUseCaseProvider = Provider<CreateSideEffectUseCase>((ref) {
  return CreateSideEffectUseCase(ref.watch(sideEffectRepositoryProvider));
});

final fetchSideEffectsUseCaseProvider = Provider<FetchSideEffectsUseCase>((ref) {
  return FetchSideEffectsUseCase(ref.watch(sideEffectRepositoryProvider));
});
