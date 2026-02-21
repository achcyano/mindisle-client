import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({required this.isSending, super.key});

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
