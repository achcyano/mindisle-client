import 'dart:developer' as developer;

import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:mindisle_client/features/ai/presentation/providers/ai_providers.dart';
import 'package:uuid/uuid.dart';

final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
      return AiChatController(ref);
    });

final class AiChatController extends StateNotifier<AiChatState> {
  AiChatController(this._ref) : super(const AiChatState());

  final Ref _ref;
  final Uuid _uuid = const Uuid();
  final InMemoryChatController chatController = InMemoryChatController();

  static const String currentUserId = 'mindisle_user';
  static const String assistantUserId = 'mindisle_ai';
  static const Duration _deltaFlushInterval = Duration(milliseconds: 40);
  static const int _initialHistoryPageSize = 12;
  static const int _historyPageSize = 30;

  final Map<UserID, User> _users = <UserID, User>{
    currentUserId: const User(id: currentUserId, name: '我'),
    assistantUserId: const User(id: assistantUserId, name: '心岛助手'),
  };

  Future<User?> resolveUser(UserID userId) async {
    return _users[userId] ?? const User(id: assistantUserId, name: '心岛助手');
  }

  Future<void> scrollToLatest({bool animated = false}) async {
    if (chatController.messages.isEmpty) return;

    final lastIndex = chatController.messages.length - 1;
    final duration = animated
        ? const Duration(milliseconds: 220)
        : Duration.zero;

    // Retry a few frames to handle async attachment timing of ChatAnimatedList.
    for (var attempt = 0; attempt < 4; attempt++) {
      await chatController.scrollToIndex(
        lastIndex,
        duration: duration,
        alignment: 1,
      );
      if (attempt < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
  }

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    if (state.initialized || state.isInitializing) return;

    state = state.copyWith(isInitializing: true, errorMessage: null);
    final conversationResult = await _ref
        .read(ensureAiConversationUseCaseProvider)
        .execute();
    switch (conversationResult) {
      case Failure<AiConversation>(error: final error):
        state = state.copyWith(
          isInitializing: false,
          errorMessage: error.message,
        );
        return;
      case Success<AiConversation>(data: final conversation):
        final messagesResult = await _ref
            .read(fetchAiMessagesUseCaseProvider)
            .execute(
              conversationId: conversation.conversationId,
              limit: _initialHistoryPageSize,
            );

        switch (messagesResult) {
          case Failure<List<AiChatMessage>>(error: final error):
            state = state.copyWith(
              initialized: true,
              isInitializing: false,
              conversationId: conversation.conversationId,
              isLoadingHistory: false,
              hasMoreHistory: false,
              earliestLoadedServerMessageId: null,
              errorMessage: error.message,
            );
            return;
          case Success<List<AiChatMessage>>(data: final messages):
            final uiMessages = _toUiMessages(messages);
            final earliestServerMessageId = _findEarliestMessageId(messages);
            final hasMoreHistory =
                messages.length >= _initialHistoryPageSize &&
                earliestServerMessageId != null;

            await chatController.setMessages(uiMessages, animated: false);
            await _enforceSingleAssistantOptions();
            state = state.copyWith(
              initialized: true,
              isInitializing: false,
              conversationId: conversation.conversationId,
              isLoadingHistory: false,
              hasMoreHistory: hasMoreHistory,
              earliestLoadedServerMessageId: earliestServerMessageId,
              errorMessage: null,
            );
            return;
        }
    }
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (state.isSending) return;

    var conversationId = state.conversationId;
    if (conversationId == null) {
      await initialize();
      conversationId = state.conversationId;
      if (conversationId == null) return;
    }

    final now = DateTime.now();
    final userId = 'user_${_uuid.v4()}';
    final assistantId = 'assistant_${_uuid.v4()}';

    final userMessage = Message.text(
      id: userId,
      authorId: currentUserId,
      createdAt: now,
      status: MessageStatus.sending,
      text: trimmed,
    );
    final assistantMessage = _buildAssistantMessage(
      id: assistantId,
      text: '',
      options: const <AiOption>[],
      createdAt: now.add(const Duration(milliseconds: 1)),
      isStreaming: true,
    );

    await chatController.insertMessage(userMessage);
    await chatController.insertMessage(assistantMessage);

    state = state.copyWith(isSending: true, errorMessage: null);

    var outcome = await _consumeStream(
      stream: _ref
          .read(streamAiConversationUseCaseProvider)
          .execute(
            conversationId: conversationId,
            userMessage: trimmed,
            clientMessageId: _uuid.v4(),
          ),
      assistantMessageId: assistantId,
    );

    if (!outcome.done &&
        !outcome.hadError &&
        outcome.generationId != null &&
        outcome.lastEventId != null) {
      outcome = await _consumeStream(
        stream: _ref
            .read(resumeAiGenerationUseCaseProvider)
            .execute(
              generationId: outcome.generationId!,
              lastEventId: outcome.lastEventId!,
            ),
        assistantMessageId: assistantId,
        seedGenerationId: outcome.generationId,
        seedLastEventId: outcome.lastEventId,
      );
    }

    if (!outcome.done && !outcome.hadError) {
      await _setAssistantStreaming(assistantId, false);
      state = state.copyWith(errorMessage: '回复中断，请重试');
    }

    final sentSuccessfully = outcome.done && !outcome.hadError;
    await _setUserMessageStatus(
      userId,
      sentSuccessfully ? MessageStatus.sent : MessageStatus.error,
    );

    state = state.copyWith(
      isSending: false,
      lastEventId: outcome.lastEventId,
      activeGenerationId: outcome.generationId,
    );
  }

  Future<void> sendOption(AiOption option) async {
    await sendText(option.payload);
  }

  Future<void> sendOptionFromMessage(
    String assistantMessageId,
    AiOption option,
  ) async {
    await _clearAssistantOptions(assistantMessageId);
    await sendText(option.payload);
  }

  Future<void> retryTextMessage(TextMessage message) async {
    await sendText(message.text);
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoadingHistory || !state.hasMoreHistory) return;

    final conversationId = state.conversationId;
    final beforeMessageId = state.earliestLoadedServerMessageId;
    if (conversationId == null || beforeMessageId == null) {
      state = state.copyWith(hasMoreHistory: false);
      return;
    }

    state = state.copyWith(isLoadingHistory: true);
    final result = await _ref
        .read(fetchAiMessagesUseCaseProvider)
        .execute(
          conversationId: conversationId,
          limit: _historyPageSize,
          beforeMessageId: beforeMessageId,
        );

    switch (result) {
      case Failure<List<AiChatMessage>>(error: final error):
        state = state.copyWith(
          isLoadingHistory: false,
          errorMessage: error.message,
        );
        return;
      case Success<List<AiChatMessage>>(data: final messages):
        if (messages.isEmpty) {
          state = state.copyWith(
            isLoadingHistory: false,
            hasMoreHistory: false,
          );
          return;
        }

        final existingMessageIds = chatController.messages
            .map((message) => message.id)
            .toSet();
        final newMessages = _toUiMessages(messages)
            .where((message) => !existingMessageIds.contains(message.id))
            .toList(growable: false);

        if (newMessages.isNotEmpty) {
          await chatController.insertAllMessages(
            newMessages,
            index: 0,
            animated: false,
          );
          await _enforceSingleAssistantOptions();
        }

        final earliestServerMessageId = _findEarliestMessageId(messages);
        final hasMoreHistory =
            messages.length >= _historyPageSize &&
            earliestServerMessageId != null &&
            earliestServerMessageId < beforeMessageId;
        state = state.copyWith(
          isLoadingHistory: false,
          hasMoreHistory: hasMoreHistory,
          earliestLoadedServerMessageId: earliestServerMessageId,
        );
        return;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<_StreamOutcome> _consumeStream({
    required Stream<AiStreamEvent> stream,
    required String assistantMessageId,
    String? seedGenerationId,
    String? seedLastEventId,
  }) async {
    var generationId = seedGenerationId;
    var lastEventId = seedLastEventId;
    var done = false;
    var hadError = false;
    var interrupted = false;
    var receivedOptions = false;
    final bufferedDelta = StringBuffer();
    DateTime? lastDeltaFlushAt;

    try {
      await for (final event in stream) {
        if (event.eventId != null && event.eventId!.isNotEmpty) {
          lastEventId = event.eventId;
        }
        if (event.generationId != null && event.generationId!.isNotEmpty) {
          generationId = event.generationId;
        }

        switch (event.type) {
          case AiStreamEventType.meta:
          case AiStreamEventType.usage:
          case AiStreamEventType.unknown:
            break;
          case AiStreamEventType.delta:
            final delta = event.delta;
            if (delta != null && delta.isNotEmpty) {
              bufferedDelta.write(delta);
              final now = DateTime.now();
              final previousFlushAt = lastDeltaFlushAt;
              final shouldFlush =
                  previousFlushAt == null ||
                  now.difference(previousFlushAt) >= _deltaFlushInterval ||
                  bufferedDelta.length >= 64;
              if (shouldFlush) {
                await _flushBufferedDelta(assistantMessageId, bufferedDelta);
                lastDeltaFlushAt = now;
              }
            }
            break;
          case AiStreamEventType.options:
            receivedOptions = true;
            await _flushBufferedDelta(assistantMessageId, bufferedDelta);
            await _setAssistantOptions(
              assistantMessageId,
              event.options,
              event.optionSource,
            );
            break;
          case AiStreamEventType.done:
            await _flushBufferedDelta(assistantMessageId, bufferedDelta);
            done = true;
            await _setAssistantStreaming(assistantMessageId, false);
            break;
          case AiStreamEventType.error:
            await _flushBufferedDelta(assistantMessageId, bufferedDelta);
            _logStreamState(
              'received error eventName=${event.eventName} code=${event.errorCode} '
              'msg=${event.errorMessage}',
            );
            if (_canResumeAfterError(
              event,
              generationId: generationId,
              lastEventId: lastEventId,
            )) {
              interrupted = true;
              break;
            }

            hadError = true;
            await _setAssistantStreaming(assistantMessageId, false);
            state = state.copyWith(
              errorMessage: event.errorMessage ?? '回复中断，请稍后重试',
            );
            break;
        }

        if (done || hadError || interrupted) {
          break;
        }
      }

      await _flushBufferedDelta(assistantMessageId, bufferedDelta);

      // Some providers close the stream after options without an explicit done event.
      if (!done && !hadError && !interrupted && receivedOptions) {
        done = true;
        await _setAssistantStreaming(assistantMessageId, false);
      }
    } catch (_) {
      if ((generationId != null && generationId.isNotEmpty) &&
          (lastEventId != null && lastEventId.isNotEmpty)) {
        _logStreamState(
          'stream exception but resumable generationId=$generationId lastEventId=$lastEventId',
        );
        return _StreamOutcome(
          generationId: generationId,
          lastEventId: lastEventId,
          done: false,
          hadError: false,
        );
      }

      hadError = true;
      await _setAssistantStreaming(assistantMessageId, false);
      state = state.copyWith(errorMessage: '回复中断，请稍后重试');
    }

    return _StreamOutcome(
      generationId: generationId,
      lastEventId: lastEventId,
      done: done,
      hadError: hadError,
    );
  }

  void _logStreamState(String message) {
    if (!kDebugMode) return;
    developer.log('[AI-CHAT] $message', name: 'mindisle.ai.chat');
  }

  bool _canResumeAfterError(
    AiStreamEvent event, {
    required String? generationId,
    required String? lastEventId,
  }) {
    if (generationId == null || generationId.isEmpty) return false;
    if (lastEventId == null || lastEventId.isEmpty) return false;

    // If server returned an explicit business code, treat as non-recoverable.
    if (event.errorCode != null || event.eventName == 'server_error') {
      return false;
    }

    return true;
  }

  Future<void> _setUserMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    final current = _findMessageById(messageId);
    if (current is! TextMessage) return;

    final now = DateTime.now();
    final metadata = Map<String, dynamic>.from(
      current.metadata ?? const <String, dynamic>{},
    );
    metadata.remove('sending');
    if (status == MessageStatus.sending) {
      metadata['sending'] = true;
    }

    final updated = current.copyWith(
      status: status,
      sentAt: status == MessageStatus.sent
          ? (current.sentAt ?? now)
          : current.sentAt,
      failedAt: status == MessageStatus.error ? now : null,
      metadata: metadata.isEmpty ? null : metadata,
    );

    await chatController.updateMessage(current, updated);
  }

  Future<void> _appendAssistantText(String messageId, String delta) async {
    final current = _findAssistantMessageById(messageId);
    if (current == null) return;

    final metadata = Map<String, dynamic>.from(
      current.metadata ?? const <String, dynamic>{},
    );
    final currentText = metadata[assistantTextKey] as String? ?? '';
    metadata[assistantTextKey] = '$currentText$delta';
    await chatController.updateMessage(
      current,
      current.copyWith(metadata: metadata),
    );
  }

  Future<void> _flushBufferedDelta(
    String messageId,
    StringBuffer buffer,
  ) async {
    if (buffer.length == 0) return;
    final delta = buffer.toString();
    buffer.clear();
    await _appendAssistantText(messageId, delta);
  }

  Future<void> _setAssistantOptions(
    String messageId,
    List<AiOption> options,
    String? source,
  ) async {
    await _clearAssistantOptionsInAllMessages(exceptMessageId: messageId);

    final current = _findAssistantMessageById(messageId);
    if (current == null) return;

    final metadata = Map<String, dynamic>.from(
      current.metadata ?? const <String, dynamic>{},
    );
    metadata[assistantOptionsKey] = options
        .map((it) => it.toJson())
        .toList(growable: false);
    metadata[assistantOptionSourceKey] = source ?? 'primary';
    await chatController.updateMessage(
      current,
      current.copyWith(metadata: metadata),
    );
  }

  Future<void> _clearAssistantOptions(String messageId) async {
    final current = _findAssistantMessageById(messageId);
    if (current == null) return;

    final metadata = Map<String, dynamic>.from(
      current.metadata ?? const <String, dynamic>{},
    );
    final rawOptions = metadata[assistantOptionsKey];
    if (rawOptions is! List || rawOptions.isEmpty) return;

    metadata[assistantOptionsKey] = const <Object>[];
    await chatController.updateMessage(
      current,
      current.copyWith(metadata: metadata),
    );
  }

  Future<void> _clearAssistantOptionsInAllMessages({
    String? exceptMessageId,
  }) async {
    final assistantMessages = chatController.messages
        .whereType<CustomMessage>()
        .where((message) => message.authorId == assistantUserId)
        .where((message) => message.id != exceptMessageId)
        .toList(growable: false);

    for (final message in assistantMessages) {
      final metadata = Map<String, dynamic>.from(
        message.metadata ?? const <String, dynamic>{},
      );
      final rawOptions = metadata[assistantOptionsKey];
      if (rawOptions is! List || rawOptions.isEmpty) {
        continue;
      }

      metadata[assistantOptionsKey] = const <Object>[];
      await chatController.updateMessage(
        message,
        message.copyWith(metadata: metadata),
      );
    }
  }

  Future<void> _enforceSingleAssistantOptions() async {
    final keepMessageId = _findLatestAssistantMessageWithOptionsId();
    await _clearAssistantOptionsInAllMessages(exceptMessageId: keepMessageId);
  }

  String? _findLatestAssistantMessageWithOptionsId() {
    final allMessages = chatController.messages;
    for (var i = allMessages.length - 1; i >= 0; i--) {
      final message = allMessages[i];
      if (message is! CustomMessage) continue;
      if (message.authorId != assistantUserId) continue;

      final rawOptions = message.metadata?[assistantOptionsKey];
      if (rawOptions is List && rawOptions.isNotEmpty) {
        return message.id;
      }
    }
    return null;
  }

  Future<void> _setAssistantStreaming(
    String messageId,
    bool isStreaming,
  ) async {
    final current = _findAssistantMessageById(messageId);
    if (current == null) return;

    final metadata = Map<String, dynamic>.from(
      current.metadata ?? const <String, dynamic>{},
    );
    metadata[assistantStreamingKey] = isStreaming;
    await chatController.updateMessage(
      current,
      current.copyWith(metadata: metadata),
    );
  }

  CustomMessage? _findAssistantMessageById(String messageId) {
    for (final message in chatController.messages) {
      if (message.id == messageId && message is CustomMessage) {
        return message;
      }
    }
    return null;
  }

  Message? _findMessageById(String messageId) {
    for (final message in chatController.messages) {
      if (message.id == messageId) {
        return message;
      }
    }
    return null;
  }

  List<Message> _toUiMessages(List<AiChatMessage> messages) {
    final uiMessages = messages.map(_toUiMessage).toList(growable: false);
    uiMessages.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    return uiMessages;
  }

  int? _findEarliestMessageId(List<AiChatMessage> messages) {
    int? earliest;
    for (final message in messages) {
      final messageId = message.messageId;
      if (messageId == null) continue;
      if (earliest == null || messageId < earliest) {
        earliest = messageId;
      }
    }
    return earliest;
  }

  Message _toUiMessage(AiChatMessage message) {
    final messageId = message.messageId?.toString() ?? _uuid.v4();

    if (message.role == AiMessageRole.user) {
      return Message.text(
        id: 'srv_user_$messageId',
        authorId: currentUserId,
        createdAt: message.createdAt,
        text: message.content,
      );
    }

    return _buildAssistantMessage(
      id: 'srv_assistant_$messageId',
      text: message.content,
      options: message.options,
      createdAt: message.createdAt,
      isStreaming: false,
    );
  }

  Message _buildAssistantMessage({
    required String id,
    required String text,
    required List<AiOption> options,
    required DateTime? createdAt,
    required bool isStreaming,
  }) {
    return Message.custom(
      id: id,
      authorId: assistantUserId,
      createdAt: createdAt,
      metadata: {
        assistantTextKey: text,
        assistantOptionsKey: options
            .map((it) => it.toJson())
            .toList(growable: false),
        assistantStreamingKey: isStreaming,
      },
    );
  }
}

final class _StreamOutcome {
  const _StreamOutcome({
    required this.generationId,
    required this.lastEventId,
    required this.done,
    required this.hadError,
  });

  final String? generationId;
  final String? lastEventId;
  final bool done;
  final bool hadError;
}
