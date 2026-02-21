import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';

AiMessageRole aiMessageRoleFromWire(String raw) {
  return switch (raw.toUpperCase()) {
    'USER' => AiMessageRole.user,
    'ASSISTANT' => AiMessageRole.assistant,
    _ => AiMessageRole.assistant,
  };
}

final class AiConversationDto {
  const AiConversationDto({
    required this.conversationId,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory AiConversationDto.fromJson(Map<String, dynamic> json) {
    final conversationId =
        (json['conversationId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0;
    return AiConversationDto(
      conversationId: conversationId,
      title: json['title'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  final int conversationId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AiConversation toDomain() {
    return AiConversation(
      conversationId: conversationId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final class AiOptionDto {
  const AiOptionDto({
    required this.id,
    required this.label,
  });

  factory AiOptionDto.fromJson(Map<String, dynamic> json) {
    return AiOptionDto(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? (json['payload'] as String? ?? ''),
    );
  }

  final String id;
  final String label;

  AiOption toDomain() {
    return AiOption(id: id, label: label);
  }
}

final class AiMessageDto {
  const AiMessageDto({
    this.messageId,
    required this.role,
    required this.content,
    this.options = const <AiOptionDto>[],
    this.generationId,
    this.createdAt,
  });

  factory AiMessageDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final parsedOptions = <AiOptionDto>[
      if (rawOptions is List)
        for (final item in rawOptions)
          if (item is Map) AiOptionDto.fromJson(Map<String, dynamic>.from(item)),
    ];

    return AiMessageDto(
      messageId: (json['messageId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt(),
      role: aiMessageRoleFromWire(json['role'] as String? ?? ''),
      content: json['content'] as String? ?? '',
      options: parsedOptions,
      generationId: json['generationId'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  final int? messageId;
  final AiMessageRole role;
  final String content;
  final List<AiOptionDto> options;
  final String? generationId;
  final DateTime? createdAt;

  AiChatMessage toDomain() {
    return AiChatMessage(
      messageId: messageId,
      role: role,
      content: content,
      options: options.map((it) => it.toDomain()).toList(growable: false),
      generationId: generationId,
      createdAt: createdAt,
    );
  }
}

final class AiSseFrame {
  const AiSseFrame({
    this.id,
    required this.event,
    required this.data,
  });

  final String? id;
  final String event;
  final String data;
}

DateTime? _parseDateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}
