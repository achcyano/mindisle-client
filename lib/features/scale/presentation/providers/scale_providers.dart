import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/scale/data/remote/scale_api.dart';
import 'package:mindisle_client/features/scale/data/repositories/scale_repository_impl.dart';
import 'package:mindisle_client/features/scale/domain/repositories/scale_repository.dart';
import 'package:mindisle_client/features/scale/domain/usecases/scale_usecases.dart';

final scaleApiProvider = Provider<ScaleApi>((ref) {
  return ScaleApi(ref.watch(appDioProvider));
});

final scaleRepositoryProvider = Provider<ScaleRepository>((ref) {
  return ScaleRepositoryImpl(ref.watch(scaleApiProvider));
});

final fetchScalesUseCaseProvider = Provider<FetchScalesUseCase>((ref) {
  return FetchScalesUseCase(ref.watch(scaleRepositoryProvider));
});

final fetchScaleDetailUseCaseProvider = Provider<FetchScaleDetailUseCase>((
  ref,
) {
  return FetchScaleDetailUseCase(ref.watch(scaleRepositoryProvider));
});

final createOrResumeScaleSessionUseCaseProvider =
    Provider<CreateOrResumeScaleSessionUseCase>((ref) {
      return CreateOrResumeScaleSessionUseCase(
        ref.watch(scaleRepositoryProvider),
      );
    });

final fetchScaleSessionDetailUseCaseProvider =
    Provider<FetchScaleSessionDetailUseCase>((ref) {
      return FetchScaleSessionDetailUseCase(ref.watch(scaleRepositoryProvider));
    });

final saveScaleAnswerUseCaseProvider = Provider<SaveScaleAnswerUseCase>((ref) {
  return SaveScaleAnswerUseCase(
        ref.watch(scaleRepositoryProvider),
      );
});

final submitScaleSessionUseCaseProvider = Provider<SubmitScaleSessionUseCase>((
  ref,
) {
  return SubmitScaleSessionUseCase(ref.watch(scaleRepositoryProvider));
});

final fetchScaleSessionResultUseCaseProvider =
    Provider<FetchScaleSessionResultUseCase>((ref) {
      return FetchScaleSessionResultUseCase(ref.watch(scaleRepositoryProvider));
    });

final fetchScaleHistoryUseCaseProvider = Provider<FetchScaleHistoryUseCase>((
  ref,
) {
  return FetchScaleHistoryUseCase(ref.watch(scaleRepositoryProvider));
});

final deleteScaleSessionUseCaseProvider = Provider<DeleteScaleSessionUseCase>((
  ref,
) {
  return DeleteScaleSessionUseCase(ref.watch(scaleRepositoryProvider));
});

final assistScaleQuestionUseCaseProvider = Provider<AssistScaleQuestionUseCase>(
  (ref) {
    return AssistScaleQuestionUseCase(ref.watch(scaleRepositoryProvider));
  },
);
