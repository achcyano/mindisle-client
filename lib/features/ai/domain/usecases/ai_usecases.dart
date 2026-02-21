import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/domain/repositories/ai_repository.dart';

final class EnsureAiConversationUseCase {
  const EnsureAiConversationUseCase(this._repository);

  final AiRepository _repository;

  Future<Result<AiConversation>> execute() {
    return _repository.ensureConversation();
  }
}

final class FetchAiMessagesUseCase {
  const FetchAiMessagesUseCase(this._repository);

  final AiRepository _repository;

  Future<Result<List<AiChatMessage>>> execute({
    required int conversationId,
    int limit = 50,
    int? beforeMessageId,
  }) {
    return _repository.fetchMessages(
      conversationId: conversationId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }
}

final class StreamAiConversationUseCase {
  const StreamAiConversationUseCase(this._repository);

  final AiRepository _repository;

  Stream<AiStreamEvent> execute({
    required int conversationId,
    required String userMessage,
    required String clientMessageId,
    double temperature = 0.7,
    int maxTokens = 2048,
    String? lastEventId,
  }) {
    return _repository.streamConversation(
      conversationId: conversationId,
      userMessage: userMessage,
      clientMessageId: clientMessageId,
      temperature: temperature,
      maxTokens: maxTokens,
      lastEventId: lastEventId,
    );
  }
}

final class ResumeAiGenerationUseCase {
  const ResumeAiGenerationUseCase(this._repository);

  final AiRepository _repository;

  Stream<AiStreamEvent> execute({
    required String generationId,
    String? lastEventId,
  }) {
    return _repository.resumeGeneration(
      generationId: generationId,
      lastEventId: lastEventId,
    );
  }
}

