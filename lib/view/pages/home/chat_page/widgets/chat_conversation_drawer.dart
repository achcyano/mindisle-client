import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_controller.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ChatConversationDrawer extends ConsumerWidget {
  const ChatConversationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiChatControllerProvider);
    final controller = ref.read(aiChatControllerProvider.notifier);
    final conversations = state.conversations;
    final selectedIndex = _selectedConversationIndex(
      conversations: conversations,
      conversationId: state.conversationId,
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '历史会话',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: '新建对话',
                  onPressed: (state.isSending || state.isInitializing)
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await controller.startNewDraftConversation();
                        },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ConversationListContent(
              state: state,
              selectedIndex: selectedIndex,
              onRefresh: () => controller.loadConversations(refresh: true),
              onSelectConversation: (conversationId) async {
                Navigator.of(context).pop();
                await controller.switchConversation(conversationId);
              },
              onLongPressConversation: (conversation) async {
                await _onConversationLongPressed(
                  context: context,
                  controller: controller,
                  conversation: conversation,
                );
              },
              conversationTitleBuilder: _conversationTitle,
              conversationTimeBuilder: _formatConversationTime,
            ),
          ),
        ],
      ),
    );
  }

  int? _selectedConversationIndex({
    required List<AiConversation> conversations,
    required int? conversationId,
  }) {
    if (conversationId == null) return null;
    final index = conversations.indexWhere(
      (item) => item.conversationId == conversationId,
    );
    if (index < 0) return null;
    return index;
  }

  String _conversationTitle(AiConversation conversation) {
    final title = conversation.title.trim();
    if (title.isEmpty) return '未命名会话';
    return title;
  }

  String _formatConversationTime(AiConversation conversation) {
    final timestamp = conversation.updatedAt ?? conversation.createdAt;
    if (timestamp == null) return '未知时间';
    final local = timestamp.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future<void> _onConversationLongPressed({
    required BuildContext context,
    required AiChatController controller,
    required AiConversation conversation,
  }) async {
    final action = await showModalBottomSheet<_ConversationMenuAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('修改标题'),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(_ConversationMenuAction.rename);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除对话'),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop(_ConversationMenuAction.delete);
                },
              ),
            ],
          ),
        );
      },
    );

    if (action == null) return;
    if (!context.mounted) return;
    switch (action) {
      case _ConversationMenuAction.rename:
        await _showRenameDialog(
          context: context,
          controller: controller,
          conversation: conversation,
        );
        return;
      case _ConversationMenuAction.delete:
        await _showDeleteDialog(
          context: context,
          controller: controller,
          conversation: conversation,
        );
        return;
    }
  }

  Future<void> _showRenameDialog({
    required BuildContext context,
    required AiChatController controller,
    required AiConversation conversation,
  }) async {
    final initial = conversation.title.trim();
    final textController = TextEditingController(text: initial);
    try {
      final title = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('修改标题'),
            content: TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: '输入新的会话标题'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final value = textController.text.trim();
                  if (value.isEmpty) return;
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      );

      if (title == null) return;
      await controller.renameConversationTitle(
        conversationId: conversation.conversationId,
        title: title,
      );
    } finally {
      textController.dispose();
    }
  }

  Future<void> _showDeleteDialog({
    required BuildContext context,
    required AiChatController controller,
    required AiConversation conversation,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除对话'),
          content: const Text('删除后不可恢复，是否继续？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await controller.deleteConversation(conversation.conversationId);
  }
}

enum _ConversationMenuAction { rename, delete }

class _ConversationListContent extends StatelessWidget {
  const _ConversationListContent({
    required this.state,
    required this.selectedIndex,
    required this.onRefresh,
    required this.onSelectConversation,
    required this.onLongPressConversation,
    required this.conversationTitleBuilder,
    required this.conversationTimeBuilder,
  });

  final AiChatState state;
  final int? selectedIndex;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int conversationId) onSelectConversation;
  final Future<void> Function(AiConversation conversation)
  onLongPressConversation;
  final String Function(AiConversation conversation) conversationTitleBuilder;
  final String Function(AiConversation conversation) conversationTimeBuilder;

  @override
  Widget build(BuildContext context) {
    final conversations = state.conversations;

    if (state.isLoadingConversations && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicatorM3E());
    }

    if (conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Text('暂无会话，向下拉可刷新，或点击加号新建会话。'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        itemCount: conversations.length,
        separatorBuilder: (context, index) {
          final colorScheme = Theme.of(context).colorScheme;
          return Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          );
        },
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final isSelected = selectedIndex == index;
          return _ConversationListItem(
            title: conversationTitleBuilder(conversation),
            subtitle: conversationTimeBuilder(conversation),
            isSelected: isSelected,
            onTap: () {
              onSelectConversation(conversation.conversationId);
            },
            onLongPress: () {
              onLongPressConversation(conversation);
            },
          );
        },
      ),
    );
  }
}

class _ConversationListItem extends StatelessWidget {
  const _ConversationListItem({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.62),
    );
    return Material(
      color: isSelected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.52)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
