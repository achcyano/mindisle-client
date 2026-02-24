import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/presentation/assist/scale_assist_controller.dart';
import 'package:mindisle_client/features/scale/presentation/assist/scale_assist_state.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

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
  static const double _bottomFollowThreshold = 36;
  static const Duration _autoFollowThrottle = Duration(milliseconds: 90);

  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  bool _shouldAutoFollowStreaming = false;
  DateTime? _lastAutoFollowAt;

  ScaleAssistArgs get _args => ScaleAssistArgs(
    sessionId: widget.sessionId,
    questionId: widget.questionId,
  );

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onListScrolled);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onListScrolled);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _shouldAutoFollowStreaming = _isNearBottom();
    await ref
        .read(scaleAssistControllerProvider(_args).notifier)
        .sendDraft(text);
    _shouldAutoFollowStreaming = false;
    _lastAutoFollowAt = null;
  }

  void _onListScrolled() {
    if (!_shouldAutoFollowStreaming) return;
    if (_isNearBottom()) return;
    _shouldAutoFollowStreaming = false;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return distanceToBottom <= _bottomFollowThreshold;
  }

  bool _didStreamTextUpdate(ScaleAssistState? previous, ScaleAssistState next) {
    if (previous == null) return false;
    if (previous.messages.isEmpty || next.messages.isEmpty) return false;
    final previousLast = previous.messages.last;
    final nextLast = next.messages.last;
    if (previousLast.id != nextLast.id) return false;
    if (!nextLast.isStreaming) return false;
    return previousLast.text != nextLast.text;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scaleAssistControllerProvider(_args));
    final controller = ref.read(scaleAssistControllerProvider(_args).notifier);

    ref.listen<ScaleAssistState>(scaleAssistControllerProvider(_args), (
      previous,
      next,
    ) {
      final sendingStarted =
          (previous?.isSending ?? false) == false && next.isSending;
      if (sendingStarted) {
        _shouldAutoFollowStreaming = _isNearBottom();
      }
      if ((previous?.isSending ?? false) && !next.isSending) {
        _shouldAutoFollowStreaming = false;
        _lastAutoFollowAt = null;
      }

      final hasNewMessages = next.messages.length != previous?.messages.length;
      final hasStreamUpdate = _didStreamTextUpdate(previous, next);
      if (_shouldAutoFollowStreaming && (hasNewMessages || hasStreamUpdate)) {
        final now = DateTime.now();
        final last = _lastAutoFollowAt;
        if (last == null || now.difference(last) >= _autoFollowThrottle) {
          _lastAutoFollowAt = now;
          _scrollToBottom();
        }
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

    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              _AssistHeader(questionStem: widget.questionStem),
              const Divider(height: 1),
              Expanded(
                child: _AssistListView(
                  messages: state.messages,
                  scrollController: _scrollController,
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: viewInsets),
                child: _AssistComposer(
                  textController: _textController,
                  isSending: state.isSending,
                  bottomPadding: 8 + safeBottom,
                  onSend: _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistHeader extends StatelessWidget {
  const _AssistHeader({required this.questionStem});

  final String questionStem;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          const Text(
            '问 AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Text(
              questionStem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistListView extends StatelessWidget {
  const _AssistListView({
    required this.messages,
    required this.scrollController,
  });

  final List<ScaleAssistMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '输入你的疑问，AI 会解释题意，但不会替你作答。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _AssistMessageItem(message: message);
      },
    );
  }
}

class _AssistComposer extends StatelessWidget {
  const _AssistComposer({
    required this.textController,
    required this.isSending,
    required this.bottomPadding,
    required this.onSend,
  });

  final TextEditingController textController;
  final bool isSending;
  final double bottomPadding;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSending)
          LinearProgressIndicator(
            minHeight: 2,
            color: colorScheme.primary,
            backgroundColor: Colors.transparent,
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 6, 8, bottomPadding),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 3,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: isSending ? '正在生成回复...' : '输入你的问题',
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: isSending ? null : onSend,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(32, 32),
                ),
                icon: Icon(
                  Icons.arrow_circle_right,
                  size: 35,
                  color: isSending
                      ? colorScheme.onSurface.withValues(alpha: 0.35)
                      : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssistMessageItem extends StatelessWidget {
  const _AssistMessageItem({required this.message});

  final ScaleAssistMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserBubbleMessage(message: message);
    }
    return _AssistantFullWidthMessage(message: message);
  }
}

class _UserBubbleMessage extends StatelessWidget {
  const _UserBubbleMessage({required this.message});

  final ScaleAssistMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(56, 0, 12, 8),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 0.6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _AssistantFullWidthMessage extends StatelessWidget {
  const _AssistantFullWidthMessage({required this.message});

  final ScaleAssistMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: message.text.isEmpty && message.isStreaming
                ? '...'
                : message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  code: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
          ),
          if (message.isStreaming) ...[
            const SizedBox(height: 8),
            SizedBox.square(
              dimension: 14,
              child: const FittedBox(child: CircularProgressIndicatorM3E()),
            ),
          ],
        ],
      ),
    );
  }
}
