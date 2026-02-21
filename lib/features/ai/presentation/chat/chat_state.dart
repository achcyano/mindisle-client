const assistantTextKey = 'assistant_text';
const assistantOptionsKey = 'assistant_options';
const assistantStreamingKey = 'assistant_streaming';
const assistantOptionSourceKey = 'assistant_option_source';

final class AiChatState {
  const AiChatState({
    this.initialized = false,
    this.isInitializing = false,
    this.isSending = false,
    this.conversationId,
    this.errorMessage,
    this.lastEventId,
    this.activeGenerationId,
  });

  final bool initialized;
  final bool isInitializing;
  final bool isSending;
  final int? conversationId;
  final String? errorMessage;
  final String? lastEventId;
  final String? activeGenerationId;

  AiChatState copyWith({
    bool? initialized,
    bool? isInitializing,
    bool? isSending,
    int? conversationId,
    Object? errorMessage = _sentinel,
    Object? lastEventId = _sentinel,
    Object? activeGenerationId = _sentinel,
  }) {
    return AiChatState(
      initialized: initialized ?? this.initialized,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      lastEventId:
          identical(lastEventId, _sentinel) ? this.lastEventId : lastEventId as String?,
      activeGenerationId: identical(activeGenerationId, _sentinel)
          ? this.activeGenerationId
          : activeGenerationId as String?,
    );
  }
}

const Object _sentinel = Object();
