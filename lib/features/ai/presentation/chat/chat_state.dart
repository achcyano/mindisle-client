const assistantTextKey = 'assistant_text';
const assistantOptionsKey = 'assistant_options';
const assistantStreamingKey = 'assistant_streaming';
const assistantOptionSourceKey = 'assistant_option_source';

final class AiChatState {
  const AiChatState({
    this.initialized = false,
    this.isInitializing = false,
    this.isSending = false,
    this.isLoadingHistory = false,
    this.hasMoreHistory = true,
    this.conversationId,
    this.earliestLoadedServerMessageId,
    this.errorMessage,
    this.lastEventId,
    this.activeGenerationId,
  });

  final bool initialized;
  final bool isInitializing;
  final bool isSending;
  final bool isLoadingHistory;
  final bool hasMoreHistory;
  final int? conversationId;
  final int? earliestLoadedServerMessageId;
  final String? errorMessage;
  final String? lastEventId;
  final String? activeGenerationId;

  AiChatState copyWith({
    bool? initialized,
    bool? isInitializing,
    bool? isSending,
    bool? isLoadingHistory,
    bool? hasMoreHistory,
    int? conversationId,
    Object? earliestLoadedServerMessageId = _sentinel,
    Object? errorMessage = _sentinel,
    Object? lastEventId = _sentinel,
    Object? activeGenerationId = _sentinel,
  }) {
    return AiChatState(
      initialized: initialized ?? this.initialized,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      conversationId: conversationId ?? this.conversationId,
      earliestLoadedServerMessageId:
          identical(earliestLoadedServerMessageId, _sentinel)
          ? this.earliestLoadedServerMessageId
          : earliestLoadedServerMessageId as int?,
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
