import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assist/scale_assist_state.dart';
import 'package:mindisle_client/features/scale/presentation/providers/scale_providers.dart';

final scaleAssistControllerProvider =
    StateNotifierProvider.family<
      ScaleAssistController,
      ScaleAssistState,
      ScaleAssistArgs
    >((ref, args) {
      return ScaleAssistController(ref, args);
    });

final class ScaleAssistController extends StateNotifier<ScaleAssistState> {
  ScaleAssistController(this._ref, this._args)
    : super(const ScaleAssistState());

  final Ref _ref;
  final ScaleAssistArgs _args;
  final Random _random = Random();

  Future<void> sendDraft(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final userMessageId = 'user_$nowMs';
    final assistantMessageId =
        'assistant_${nowMs + 1}_${_random.nextInt(1000)}';

    state = state.copyWith(
      isSending: true,
      errorMessage: null,
      messages: <ScaleAssistMessage>[
        ...state.messages,
        ScaleAssistMessage(id: userMessageId, text: text, isUser: true),
        ScaleAssistMessage(
          id: assistantMessageId,
          text: '',
          isUser: false,
          isStreaming: true,
        ),
      ],
    );

    try {
      await for (final event
          in _ref
              .read(assistScaleQuestionUseCaseProvider)
              .execute(
                sessionId: _args.sessionId,
                questionId: _args.questionId,
                userDraftAnswer: text,
              )) {
        if (!mounted) return;

        switch (event.type) {
          case ScaleAssistEventType.meta:
          case ScaleAssistEventType.unknown:
            break;
          case ScaleAssistEventType.delta:
            final delta = event.delta ?? '';
            if (delta.isEmpty) break;
            _appendToAssistantMessage(assistantMessageId, delta);
            break;
          case ScaleAssistEventType.done:
            _finishAssistantMessage(assistantMessageId);
            state = state.copyWith(isSending: false);
            return;
          case ScaleAssistEventType.error:
            _finishAssistantMessage(assistantMessageId);
            state = state.copyWith(
              isSending: false,
              errorMessage: event.errorMessage ?? 'AI 回复中断，请稍后重试',
            );
            return;
        }
      }

      if (!mounted) return;
      _finishAssistantMessage(assistantMessageId);
      state = state.copyWith(isSending: false);
    } catch (_) {
      if (!mounted) return;
      _finishAssistantMessage(assistantMessageId);
      state = state.copyWith(isSending: false, errorMessage: 'AI 回复中断，请稍后重试');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _appendToAssistantMessage(String messageId, String delta) {
    final messages = state.messages
        .map((message) {
          if (message.id != messageId) return message;
          return message.copyWith(text: '${message.text}$delta');
        })
        .toList(growable: false);
    state = state.copyWith(messages: messages);
  }

  void _finishAssistantMessage(String messageId) {
    final messages = state.messages
        .map((message) {
          if (message.id != messageId) return message;
          return message.copyWith(isStreaming: false);
        })
        .toList(growable: false);
    state = state.copyWith(messages: messages);
  }
}
