import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_option_tile.dart';

class QuestionStepCard extends StatelessWidget {
  const QuestionStepCard({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onSelectOption,
    required this.onAskAi,
    this.isSaving = false,
    this.enabled = true,
  });

  final ScaleQuestion question;
  final int? selectedOptionId;
  final bool isSaving;
  final bool enabled;
  final ValueChanged<ScaleQuestionOption> onSelectOption;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.stem,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '问 AI',
                  onPressed: enabled ? onAskAi : null,
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.78,
                    ),
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  icon: const Icon(Icons.question_mark_rounded, size: 18),
                ),
              ],
            ),
            if ((question.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                question.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (isSaving)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            const SizedBox(height: 10),
            if (question.type == ScaleQuestionType.singleChoice) ...[
              for (final option in question.options) ...[
                ScaleOptionTile(
                  label: option.label,
                  selected:
                      selectedOptionId != null &&
                      option.optionId != null &&
                      selectedOptionId == option.optionId,
                  enabled: enabled,
                  onTap: () {
                    onSelectOption(option);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ] else ...[
              Text(
                '当前版本仅支持单选题作答。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
