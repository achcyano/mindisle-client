import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({required this.isSending, super.key});

  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
      child: Composer(
        sigmaX: 0,
        sigmaY: 0,
        hintText: isSending ? '正在生成回复...' : '输入消息',
        minLines: 1,
        maxLines: 3,
        gap: 6,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        inputBorder: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        sendOnEnter: true,
        sendButtonDisabled: isSending,
        sendButtonVisibilityMode: SendButtonVisibilityMode.disabled,
        backgroundColor: colorScheme.surface,
        inputFillColor: colorScheme.surfaceContainerLow,
        sendIcon: const Icon(Icons.arrow_circle_right, size: 27),
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
      ),
    );
  }
}
