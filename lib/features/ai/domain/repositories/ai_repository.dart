import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';

abstract interface class AiRepository {
  Future<Result<AiConversation>> ensureConversation();

  Future<Result<List<AiConversation>>> fetchConversations({
    int limit,
    String? cursor,
  });

  Future<Result<AiConversation>> createConversation({String? title});

  Future<Result<AiConversation>> updateConversationTitle({
    required int conversationId,
    required String title,
  });

  Future<Result<bool>> deleteConversation({
    required int conversationId,
  });

  Future<Result<List<AiChatMessage>>> fetchMessages({
    required int conversationId,
    int limit,
    int? beforeMessageId,
  });

  Stream<AiStreamEvent> streamConversation({
    required int conversationId,
    required String userMessage,
    required String clientMessageId,
    double temperature,
    int maxTokens,
    String? lastEventId,
  });

  Stream<AiStreamEvent> resumeGeneration({
    required String generationId,
    String? lastEventId,
  });
}
