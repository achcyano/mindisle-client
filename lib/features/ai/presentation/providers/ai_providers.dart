import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/ai/data/remote/ai_api.dart';
import 'package:mindisle_client/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:mindisle_client/features/ai/domain/repositories/ai_repository.dart';
import 'package:mindisle_client/features/ai/domain/usecases/ai_usecases.dart';

final aiApiProvider = Provider<AiApi>((ref) {
  return AiApi(ref.watch(appDioProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.watch(aiApiProvider));
});

final ensureAiConversationUseCaseProvider = Provider<EnsureAiConversationUseCase>((ref) {
  return EnsureAiConversationUseCase(ref.watch(aiRepositoryProvider));
});

final fetchAiMessagesUseCaseProvider = Provider<FetchAiMessagesUseCase>((ref) {
  return FetchAiMessagesUseCase(ref.watch(aiRepositoryProvider));
});

final streamAiConversationUseCaseProvider = Provider<StreamAiConversationUseCase>((ref) {
  return StreamAiConversationUseCase(ref.watch(aiRepositoryProvider));
});

final resumeAiGenerationUseCaseProvider = Provider<ResumeAiGenerationUseCase>((ref) {
  return ResumeAiGenerationUseCase(ref.watch(aiRepositoryProvider));
});

