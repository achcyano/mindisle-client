import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class UserTextMessageBubble extends StatelessWidget {
  const UserTextMessageBubble({
    required this.message,
    required this.index,
    required this.isSentByMe,
    this.onRetry,
    super.key,
  });

  final TextMessage message;
  final int index;
  final bool isSentByMe;
  final VoidCallback? onRetry;

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
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('重试发送'),
          ),
        ],
      ],
    );
  }
}
