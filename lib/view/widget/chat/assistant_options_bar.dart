import 'package:flutter/material.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';

class AssistantOptionsBar extends StatelessWidget {
  const AssistantOptionsBar({
    required this.options,
    required this.onOptionPressed,
    this.enabled = true,
    super.key,
  });

  final List<AiOption> options;
  final ValueChanged<AiOption> onOptionPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options.take(3))
          FilledButton.tonal(
            onPressed: enabled ? () => onOptionPressed(option) : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(option.label),
          ),
      ],
    );
  }
}

