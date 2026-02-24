import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/presentation/assist/scale_assist_controller.dart';
import 'package:mindisle_client/features/scale/presentation/assist/scale_assist_state.dart';

class ScaleAssistBottomSheet extends ConsumerStatefulWidget {
  const ScaleAssistBottomSheet({
    super.key,
    required this.sessionId,
    required this.questionId,
    required this.questionStem,
  });

  final int sessionId;
  final int questionId;
  final String questionStem;

  @override
  ConsumerState<ScaleAssistBottomSheet> createState() =>
      _ScaleAssistBottomSheetState();
}

class _ScaleAssistBottomSheetState
    extends ConsumerState<ScaleAssistBottomSheet> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  ScaleAssistArgs get _args => ScaleAssistArgs(
    sessionId: widget.sessionId,
    questionId: widget.questionId,
  );

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref
        .read(scaleAssistControllerProvider(_args).notifier)
        .sendDraft(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scaleAssistControllerProvider(_args));
    final controller = ref.read(scaleAssistControllerProvider(_args).notifier);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<ScaleAssistState>(scaleAssistControllerProvider(_args), (
      previous,
      next,
    ) {
      if (next.messages.length != previous?.messages.length) {
        _scrollToBottom();
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
      controller.clearError();
    });

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '题目 AI 辅助',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.questionStem,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.messages.isEmpty
                  ? Center(
                      child: Text(
                        '输入你的困惑，AI 会解释题意但不会自动替你作答。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _AssistBubble(message: message);
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                6,
                12,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '输入想问的问题...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isSending ? null : _send,
                    icon: state.isSending
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistBubble extends StatelessWidget {
  const _AssistBubble({required this.message});

  final ScaleAssistMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                message.text.isEmpty && message.isStreaming
                    ? '思考中...'
                    : message.text,
              ),
            ),
            if (message.isStreaming) ...[
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
