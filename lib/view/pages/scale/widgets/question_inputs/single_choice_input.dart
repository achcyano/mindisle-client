import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';
import 'package:mindisle_client/view/pages/scale/widgets/scale_option_tile.dart';

class SingleChoiceInput extends StatelessWidget {
  const SingleChoiceInput({
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onDraftChanged,
    super.key,
  });

  final ScaleQuestion question;
  final ScaleAnswerDraft? draft;
  final bool enabled;
  final ScaleAnswerDraftChanged onDraftChanged;

  @override
  Widget build(BuildContext context) {
    if (question.options.isEmpty) {
      return _InvalidOptionsHint();
    }

    return Column(
      children: [
        for (final option in question.options) ...[
          ScaleOptionTile(
            label: option.label,
            selected: draft?.optionId != null && draft?.optionId == option.optionId,
            enabled: enabled,
            onTap: () {
              final optionId = option.optionId;
              if (optionId == null) return;
              onDraftChanged(
                ScaleAnswerDraft.singleChoice(optionId: optionId),
                true,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _InvalidOptionsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '题目缺少可用选项，请联系管理员。',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }
}
