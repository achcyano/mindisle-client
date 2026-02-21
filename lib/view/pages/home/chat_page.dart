import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_controller.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:mindisle_client/view/widget/chat/assistant_options_bar.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiChatState>(aiChatControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty || message == previous?.errorMessage) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      ref.read(aiChatControllerProvider.notifier).clearError();
    });

    final state = ref.watch(aiChatControllerProvider);
    final controller = ref.read(aiChatControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('心岛助手')),
      body: state.isInitializing
          ? const Center(child: CircularProgressIndicatorM3E())
          : Chat(
              chatController: controller.chatController,
              currentUserId: AiChatController.currentUserId,
              resolveUser: controller.resolveUser,
              onMessageSend: controller.sendText,
              builders: Builders(
                customMessageBuilder: (
                  BuildContext context,
                  CustomMessage message,
                  int index, {
                  MessageGroupStatus? groupStatus,
                  required bool isSentByMe,
                }) {
                  return _AssistantMessageBubble(
                    message: message,
                    isSending: state.isSending,
                    onOptionPressed: controller.sendOption,
                  );
                },
              ),
            ),
    );
  }
}

class _AssistantMessageBubble extends StatelessWidget {
  const _AssistantMessageBubble({
    required this.message,
    required this.isSending,
    required this.onOptionPressed,
  });

  final CustomMessage message;
  final bool isSending;
  final ValueChanged<AiOption> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? const <String, dynamic>{};
    final text = metadata[assistantTextKey] as String? ?? '';
    final options = _decodeOptions(metadata[assistantOptionsKey]);
    final isStreaming = metadata[assistantStreamingKey] == true;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.isEmpty && isStreaming ? '...' : text,
                  style: textTheme.bodyMedium,
                ),
                if (isStreaming) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AssistantOptionsBar(
                    options: options,
                    enabled: !isSending,
                    onOptionPressed: onOptionPressed,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AiOption> _decodeOptions(Object? rawOptions) {
    if (rawOptions is! List) return const <AiOption>[];

    return rawOptions
        .whereType<Map>()
        .map((item) => AiOption.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.label.isNotEmpty && item.payload.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }
}

