import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/duration_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/multi_choice_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/single_choice_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/text_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/time_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/unsupported_input.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/yes_no_input.dart';

typedef ScaleAnswerDraftChanged =
    void Function(ScaleAnswerDraft draft, bool saveNow);

class QuestionInputFactory extends StatelessWidget {
  const QuestionInputFactory({
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
    switch (question.type) {
      case ScaleQuestionType.singleChoice:
        return SingleChoiceInput(
          question: question,
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.yesNo:
        return YesNoInput(
          question: question,
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.multiChoice:
        return MultiChoiceInput(
          question: question,
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.text:
        return TextInput(
          key: ValueKey<int>(question.questionId),
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.time:
        return TimeInput(
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.duration:
        return DurationInput(
          draft: draft,
          enabled: enabled,
          onDraftChanged: onDraftChanged,
        );
      case ScaleQuestionType.unknown:
        return const UnsupportedInput();
    }
  }
}
