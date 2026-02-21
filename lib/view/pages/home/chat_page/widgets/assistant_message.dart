import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/presentation/chat/chat_state.dart';

class AssistantMessageContent extends StatelessWidget {
  const AssistantMessageContent({
    required this.message,
    required this.isSending,
    required this.onOptionPressed,
    super.key,
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
    final maxWidth = MediaQuery.of(context).size.width * 0.92;
    final markdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context))
        .copyWith(
          p: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          codeblockDecoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.8, color: colorScheme.outlineVariant),
            ),
          ),
          code: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
        );

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                Align(
                  alignment: Alignment.center,
                  child: Text('...', style: textTheme.bodyMedium),
                )
              else
                Align(
                  alignment: Alignment.center,
                  child: MarkdownBody(
                    data: text,
                    styleSheet: markdownStyle,
                    selectable: true,
                  ),
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
                const SizedBox(height: 12),
                _AssistantOptionsColumn(
                  options: options,
                  enabled: !isSending,
                  onOptionPressed: onOptionPressed,
                ),
              ],
            ],
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

class _AssistantOptionsColumn extends StatelessWidget {
  const _AssistantOptionsColumn({
    required this.options,
    required this.enabled,
    required this.onOptionPressed,
  });

  final List<AiOption> options;
  final bool enabled;
  final ValueChanged<AiOption> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  onTap: enabled ? () => onOptionPressed(option) : null,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: enabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
