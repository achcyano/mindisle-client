import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_controller.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/assistant_message.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/chat_composer.dart';
import 'package:mindisle_client/view/pages/home/chat_page/widgets/chat_conversation_drawer.dart';
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
  static const double _chatBottomThreshold = 48;
  static const Duration _chatAutoFollowThrottle = Duration(milliseconds: 90);

  bool _isActiveInTickerMode = false;
  bool _shouldAutoFollowStreaming = false;
  bool _hasSendStartFollowDecision = false;
  DateTime? _lastAutoFollowAt;
  late final ScrollController _chatScrollController;
  StreamSubscription<ChatOperation>? _chatOperationSubscription;

  @override
  void initState() {
    super.initState();
    _chatScrollController = ScrollController()..addListener(_onChatScrolled);
    _bindChatOperationStream();
  }

  @override
  void dispose() {
    _chatOperationSubscription?.cancel();
    _chatScrollController.removeListener(_onChatScrolled);
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPageActivation();
  }

  void _syncPageActivation() {
    final isActive = TickerMode.of(context);
    if (isActive == _isActiveInTickerMode) return;
    _isActiveInTickerMode = isActive;
    if (!isActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = ref.read(aiChatControllerProvider.notifier);
      await controller.startNewDraftConversation(refreshConversations: true);
    });
  }

  void _bindChatOperationStream() {
    final aiController = ref.read(aiChatControllerProvider.notifier);
    _chatOperationSubscription = aiController.chatController.operationsStream
        .listen(_onChatOperation);
  }

  void _onChatOperation(ChatOperation operation) {
    if (!_shouldAutoFollowStreaming) return;
    if (operation.type != ChatOperationType.update) return;
    final message = operation.message;
    if (message == null) return;
    if (message.authorId != AiChatController.assistantUserId) return;
    final metadata = message.metadata;
    if (metadata == null || metadata[assistantStreamingKey] != true) return;
    if (!ref.read(aiChatControllerProvider).isSending) return;

    final now = DateTime.now();
    final last = _lastAutoFollowAt;
    if (last != null && now.difference(last) < _chatAutoFollowThrottle) return;
    _lastAutoFollowAt = now;

    unawaited(_scrollChatToLatest());
  }

  void _onChatScrolled() {
    if (!_shouldAutoFollowStreaming) return;
    if (_isChatNearBottom()) return;
    _shouldAutoFollowStreaming = false;
  }

  bool _isChatNearBottom() {
    if (!_chatScrollController.hasClients) return true;
    final position = _chatScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return distanceToBottom <= _chatBottomThreshold;
  }

  Future<void> _scrollChatToLatest() async {
    if (!mounted || !_shouldAutoFollowStreaming) return;
    final aiController = ref.read(aiChatControllerProvider.notifier);
    final messages = aiController.chatController.messages;
    if (messages.isEmpty) return;
    await aiController.chatController.scrollToIndex(
      messages.length - 1,
      alignment: 1,
      duration: Duration.zero,
    );
  }

  void _prepareAutoFollowForSend() {
    _shouldAutoFollowStreaming = _isChatNearBottom();
    _hasSendStartFollowDecision = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiChatState>(aiChatControllerProvider, (previous, next) {
      final sendingStarted =
          (previous?.isSending ?? false) == false && next.isSending;
      if (sendingStarted && !_hasSendStartFollowDecision) {
        _shouldAutoFollowStreaming = _isChatNearBottom();
      }
      if ((previous?.isSending ?? false) && !next.isSending) {
        _shouldAutoFollowStreaming = false;
        _hasSendStartFollowDecision = false;
        _lastAutoFollowAt = null;
      }

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
    final appBarTitle = _resolveCurrentConversationTitle(state);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(appBarTitle),
      ),
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const ChatConversationDrawer(),
      ),
      onDrawerChanged: (isOpened) {
        if (!isOpened) return;
        controller.loadConversations();
      },
      body: SafeArea(
        top: false,
        child: state.isInitializing
            ? const Center(child: CircularProgressIndicatorM3E())
            : Column(
                children: [
                  Expanded(
                    child: Chat(
                      chatController: controller.chatController,
                      currentUserId: AiChatController.currentUserId,
                      resolveUser: controller.resolveUser,
                      onMessageSend: (text) async {
                        if (text.trim().isEmpty) return;
                        _prepareAutoFollowForSend();
                        await controller.sendText(text);
                      },
                      backgroundColor: colorScheme.surface,
                      theme: ChatTheme.fromThemeData(Theme.of(context))
                          .copyWith(
                            shape: const BorderRadius.all(Radius.circular(16)),
                          ),
                      builders: Builders(
                        chatAnimatedListBuilder: (context, itemBuilder) {
                          return ChatAnimatedList(
                            itemBuilder: itemBuilder,
                            scrollController: _chatScrollController,
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
                                        message.resolvedStatus ==
                                            MessageStatus.error
                                    ? () async {
                                        _prepareAutoFollowForSend();
                                        await controller.retryTextMessage(
                                          message,
                                        );
                                      }
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
                                  _prepareAutoFollowForSend();
                                  controller.sendOptionFromMessage(
                                    message.id,
                                    option,
                                  );
                                },
                              );
                            },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      'AI建议仅供参考，如有疑问请咨询医生',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _resolveCurrentConversationTitle(AiChatState state) {
    final conversationId = state.conversationId;
    if (conversationId == null) return '新对话';

    for (final conversation in state.conversations) {
      if (conversation.conversationId != conversationId) continue;
      final title = conversation.title.trim();
      if (title.isEmpty) return '未命名会话';
      return title;
    }
    return '对话';
  }
}
