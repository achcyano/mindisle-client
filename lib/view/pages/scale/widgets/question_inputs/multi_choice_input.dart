import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';
import 'package:mindisle_client/view/pages/scale/widgets/scale_option_tile.dart';

class MultiChoiceInput extends StatelessWidget {
  const MultiChoiceInput({
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
      return _MultiChoiceInvalidOptionsHint();
    }

    final selectedIds = draft?.optionIds.toSet() ?? <int>{};

    return Column(
      children: [
        for (final option in question.options) ...[
          ScaleOptionTile(
            label: option.label,
            selected:
                option.optionId != null && selectedIds.contains(option.optionId),
            enabled: enabled,
            selectedIcon: Icons.check_box_rounded,
            unselectedIcon: Icons.check_box_outline_blank_rounded,
            onTap: () {
              final optionId = option.optionId;
              if (optionId == null) return;

              final toggled = <int>{...selectedIds};
              if (!toggled.add(optionId)) {
                toggled.remove(optionId);
              }

              final sortedSelected = question.options
                  .where((it) => it.optionId != null && toggled.contains(it.optionId))
                  .map((it) => it.optionId!)
                  .toList(growable: false);

              onDraftChanged(
                ScaleAnswerDraft.multiChoice(optionIds: sortedSelected),
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

class _MultiChoiceInvalidOptionsHint extends StatelessWidget {
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
