import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_controller.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/chat/assistant_options_bar.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  static final route = AppRoute<void>(
    path: '/home/chat',
    builder: (_) => const ChatPage(),
  );

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  Future<void> _onMessageLongPress(
    BuildContext context,
    Message message, {
    required int index,
    required LongPressStartDetails details,
  }) async {
    final messageText = _extractMessageText(message);
    final canCopy = messageText != null && messageText.trim().isNotEmpty;
    final canRetry =
        message is TextMessage &&
        message.authorId == AiChatController.currentUserId &&
        message.resolvedStatus == MessageStatus.error &&
        message.text.trim().isNotEmpty;
    if (!canCopy && !canRetry) return;

    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canCopy)
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: const Text('复制'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_MessageAction.copy),
                ),
              if (canRetry)
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('重试发送'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_MessageAction.retry),
                ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _MessageAction.copy:
        if (!canCopy) return;
        await Clipboard.setData(ClipboardData(text: messageText));
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(const SnackBar(content: Text('已复制内容')));
        return;
      case _MessageAction.retry:
        if (!canRetry) return;
        await ref
            .read(aiChatControllerProvider.notifier)
            .retryTextMessage(message);
        return;
    }
  }

  String? _extractMessageText(Message message) {
    if (message is TextMessage) return message.text;
    if (message is! CustomMessage) return null;

    final metadata = message.metadata ?? const <String, dynamic>{};
    final text = metadata[assistantTextKey];
    if (text is! String || text.trim().isEmpty) return null;
    return text;
  }

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
      if (message == null ||
          message.isEmpty ||
          message == previous?.errorMessage) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      ref.read(aiChatControllerProvider.notifier).clearError();
    });

    final state = ref.watch(aiChatControllerProvider);
    final controller = ref.read(aiChatControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: state.isInitializing
          ? const Center(child: CircularProgressIndicatorM3E())
          : Chat(
              chatController: controller.chatController,
              currentUserId: AiChatController.currentUserId,
              resolveUser: controller.resolveUser,
              onMessageSend: controller.sendText,
              onMessageLongPress: _onMessageLongPress,
              backgroundColor: colorScheme.surface,
              theme: ChatTheme.fromThemeData(
                Theme.of(context),
              ).copyWith(shape: const BorderRadius.all(Radius.circular(16))),
              builders: Builders(
                chatAnimatedListBuilder: (context, itemBuilder) {
                  return ChatAnimatedList(
                    itemBuilder: itemBuilder,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    initialScrollToEndMode: InitialScrollToEndMode.jump,
                    onEndReached: state.hasMoreHistory
                        ? controller.loadOlderMessages
                        : null,
                    topSliver: state.isLoadingHistory
                        ? const SliverToBoxAdapter(
                            child: _HistoryLoadingIndicator(),
                          )
                        : null,
                  );
                },
                composerBuilder: (context) {
                  return _ChatComposer(isSending: state.isSending);
                },
                emptyChatListBuilder: (context) {
                  return const _ChatEmptyState();
                },
                textMessageBuilder:
                    (
                      BuildContext context,
                      TextMessage message,
                      int index, {
                      required bool isSentByMe,
                      MessageGroupStatus? groupStatus,
                    }) {
                      return _UserTextMessageBubble(
                        message: message,
                        index: index,
                        isSentByMe: isSentByMe,
                      );
                    },
                customMessageBuilder:
                    (
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
    final optionSourceRaw = metadata[assistantOptionSourceKey];
    final optionSource = optionSourceRaw is String ? optionSourceRaw : null;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    final markdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context))
        .copyWith(
          p: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          code: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (optionSource != null && optionSource.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      optionSource,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (text.isEmpty && isStreaming)
                  Text('...', style: textTheme.bodyMedium)
                else
                  MarkdownBody(data: text, styleSheet: markdownStyle),
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

class _UserTextMessageBubble extends StatelessWidget {
  const _UserTextMessageBubble({
    required this.message,
    required this.index,
    required this.isSentByMe,
  });

  final TextMessage message;
  final int index;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeColor =
        (isSentByMe
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.72);
    final isFailed =
        isSentByMe && message.resolvedStatus == MessageStatus.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isSentByMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SimpleTextMessage(
          message: message,
          index: index,
          showTime: true,
          showStatus: true,
          borderRadius: BorderRadius.circular(16),
          sentBackgroundColor: colorScheme.primaryContainer,
          sentTextStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
          receivedBackgroundColor: colorScheme.surfaceContainerHighest,
          receivedTextStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          timeStyle: textTheme.labelSmall?.copyWith(color: timeColor),
        ),
        if (isFailed) ...[
          const SizedBox(height: 4),
          Text(
            '发送失败，长按重试',
            style: textTheme.labelSmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _HistoryLoadingIndicator extends StatelessWidget {
  const _HistoryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.isSending});

  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Composer(
      sigmaX: 0,
      sigmaY: 0,
      hintText: isSending ? '正在生成回复...' : '输入消息',
      maxLines: 6,
      sendOnEnter: true,
      sendButtonDisabled: isSending,
      sendButtonVisibilityMode: SendButtonVisibilityMode.disabled,
      backgroundColor: colorScheme.surfaceContainerLow,
      inputFillColor: colorScheme.surface,
      sendIconColor: colorScheme.primary,
      emptyFieldSendIconColor: colorScheme.onSurface.withValues(alpha: 0.35),
      hintColor: colorScheme.onSurfaceVariant,
      topWidget: isSending
          ? LinearProgressIndicator(
              minHeight: 2,
              color: colorScheme.primary,
              backgroundColor: Colors.transparent,
            )
          : null,
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text('开始一段对话', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '可直接提问，或等待助手给出建议选项',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MessageAction { copy, retry }
