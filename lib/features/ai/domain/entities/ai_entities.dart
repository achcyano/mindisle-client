enum AiMessageRole {
  user,
  assistant,
}

final class AiOption {
  const AiOption({
    required this.id,
    required this.label,
    required this.payload,
  });

  final String id;
  final String label;
  final String payload;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'payload': payload,
    };
  }

  factory AiOption.fromJson(Map<String, dynamic> json) {
    return AiOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
    );
  }
}

final class AiConversation {
  const AiConversation({
    required this.conversationId,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  final int conversationId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

final class AiChatMessage {
  const AiChatMessage({
    this.messageId,
    required this.role,
    required this.content,
    this.options = const <AiOption>[],
    this.generationId,
    this.createdAt,
  });

  final int? messageId;
  final AiMessageRole role;
  final String content;
  final List<AiOption> options;
  final String? generationId;
  final DateTime? createdAt;
}

enum AiStreamEventType {
  meta,
  delta,
  usage,
  options,
  done,
  error,
  unknown,
}

final class AiStreamEvent {
  const AiStreamEvent({
    required this.type,
    this.eventId,
    this.eventName,
    this.generationId,
    this.delta,
    this.usage,
    this.options = const <AiOption>[],
    this.optionSource,
    this.errorCode,
    this.errorMessage,
  });

  final AiStreamEventType type;
  final String? eventId;
  final String? eventName;
  final String? generationId;
  final String? delta;
  final Map<String, dynamic>? usage;
  final List<AiOption> options;
  final String? optionSource;
  final int? errorCode;
  final String? errorMessage;
}

