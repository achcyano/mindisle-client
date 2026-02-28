import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/single_choice_input.dart';

class YesNoInput extends StatelessWidget {
  const YesNoInput({
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
    return SingleChoiceInput(
      question: question,
      draft: draft,
      enabled: enabled,
      onDraftChanged: onDraftChanged,
    );
  }
}
