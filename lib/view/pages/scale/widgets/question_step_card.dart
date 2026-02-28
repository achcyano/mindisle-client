import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';

class QuestionStepCard extends StatelessWidget {
  const QuestionStepCard({
    super.key,
    required this.question,
    required this.draft,
    required this.onDraftChanged,
    required this.onAskAi,
    this.isSaving = false,
    this.enabled = true,
  });

  final ScaleQuestion question;
  final ScaleAnswerDraft? draft;
  final bool isSaving;
  final bool enabled;
  final ScaleAnswerDraftChanged onDraftChanged;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
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
                  tooltip: '闂?AI',
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
            QuestionInputFactory(
              question: question,
              draft: draft,
              enabled: enabled,
              onDraftChanged: onDraftChanged,
            ),
          ],
        ),
      ),
    );
  }
}
