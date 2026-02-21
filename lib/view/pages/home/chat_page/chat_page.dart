import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_controller.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/assistant_message.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/chat_composer.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/chat_empty_state.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/history_loading_indicator.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/user_text_message.dart';
import 'package:mindisle_client/view/route/app_route.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(aiChatControllerProvider.notifier);
      await controller.initialize();
      if (!mounted) return;
      await controller.scrollToLatest();
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
                            child: HistoryLoadingIndicator(),
                          )
                        : null,
                  );
                },
                composerBuilder: (context) {
                  return ChatComposer(isSending: state.isSending);
                },
                emptyChatListBuilder: (context) {
                  return const ChatEmptyState();
                },
                textMessageBuilder:
                    (
                      BuildContext context,
                      TextMessage message,
                      int index, {
                      required bool isSentByMe,
                      MessageGroupStatus? groupStatus,
                    }) {
                      return UserTextMessageBubble(
                        message: message,
                        index: index,
                        isSentByMe: isSentByMe,
                        onRetry:
                            isSentByMe &&
                                message.resolvedStatus == MessageStatus.error
                            ? () => controller.retryTextMessage(message)
                            : null,
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
                      return AssistantMessageContent(
                        message: message,
                        isSending: state.isSending,
                        onOptionPressed: (option) {
                          controller.sendOptionFromMessage(message.id, option);
                        },
                      );
                    },
              ),
            ),
    );
  }
}
