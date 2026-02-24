final class ScaleAssistArgs {
  const ScaleAssistArgs({required this.sessionId, required this.questionId});

  final int sessionId;
  final int questionId;

  @override
  bool operator ==(Object other) {
    return other is ScaleAssistArgs &&
        other.sessionId == sessionId &&
        other.questionId == questionId;
  }

  @override
  int get hashCode => Object.hash(sessionId, questionId);
}

final class ScaleAssistMessage {
  const ScaleAssistMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final bool isStreaming;

  ScaleAssistMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    bool? isStreaming,
  }) {
    return ScaleAssistMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

final class ScaleAssistState {
  const ScaleAssistState({
    this.messages = const <ScaleAssistMessage>[],
    this.isSending = false,
    this.errorMessage,
  });

  final List<ScaleAssistMessage> messages;
  final bool isSending;
  final String? errorMessage;

  ScaleAssistState copyWith({
    List<ScaleAssistMessage>? messages,
    bool? isSending,
    Object? errorMessage = _sentinel,
  }) {
    return ScaleAssistState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
