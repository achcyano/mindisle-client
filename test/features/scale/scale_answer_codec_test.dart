import 'package:flutter_test/flutter_test.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_codec.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';

void main() {
  group('ScaleAnswerCodec', () {
    final questions = <ScaleQuestion>[
      _question(id: 1, type: ScaleQuestionType.singleChoice),
      _question(id: 2, type: ScaleQuestionType.multiChoice),
      _question(id: 3, type: ScaleQuestionType.yesNo),
      _question(id: 4, type: ScaleQuestionType.text),
      _question(id: 5, type: ScaleQuestionType.time),
      _question(id: 6, type: ScaleQuestionType.duration),
    ];

    test('fromSessionAnswers parses all supported question types', () {
      final drafts = ScaleAnswerCodec.fromSessionAnswers(
        questions: questions,
        answers: const <ScaleAnswer>[
          ScaleAnswer(
            questionId: 1,
            rawAnswer: <String, dynamic>{'optionId': 10},
            selectedOptionId: 10,
          ),
          ScaleAnswer(
            questionId: 2,
            rawAnswer: <String, dynamic>{'optionIds': <int>[3, 1]},
            selectedOptionIds: <int>[3, 1],
          ),
          ScaleAnswer(
            questionId: 3,
            rawAnswer: <String, dynamic>{'optionId': 20},
            selectedOptionId: 20,
          ),
          ScaleAnswer(
            questionId: 4,
            rawAnswer: <String, dynamic>{'text': ' 睡眠变差 '},
            textValue: ' 睡眠变差 ',
          ),
          ScaleAnswer(
            questionId: 5,
            rawAnswer: <String, dynamic>{'value': '08:30'},
          ),
          ScaleAnswer(
            questionId: 6,
            rawAnswer: <String, dynamic>{'value': '6:30'},
          ),
        ],
      );

      expect(drafts[1]?.optionId, 10);
      expect(drafts[2]?.optionIds, <int>[1, 3]);
      expect(drafts[3]?.optionId, 20);
      expect(drafts[4]?.textValue, '睡眠变差');
      expect(drafts[5]?.timeValue, '08:30');
      expect(drafts[6]?.durationMinutes, 390);
    });

    test('parses numeric duration like backend evaluator', () {
      final durationQuestion = _question(id: 6, type: ScaleQuestionType.duration);

      final hoursLike = ScaleAnswerCodec.fromSessionAnswers(
        questions: <ScaleQuestion>[durationQuestion],
        answers: const <ScaleAnswer>[
          ScaleAnswer(questionId: 6, rawAnswer: <String, dynamic>{'value': '12'}),
        ],
      );
      final minutesLike = ScaleAnswerCodec.fromSessionAnswers(
        questions: <ScaleQuestion>[durationQuestion],
        answers: const <ScaleAnswer>[
          ScaleAnswer(questionId: 6, rawAnswer: <String, dynamic>{'value': '90'}),
        ],
      );

      expect(hoursLike[6]?.durationMinutes, 720);
      expect(minutesLike[6]?.durationMinutes, 90);
    });

    test('toRequestAnswer builds payload for all supported question types', () {
      final singlePayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[0],
        draft: const ScaleAnswerDraft.singleChoice(optionId: 10),
      );
      final multiPayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[1],
        draft: const ScaleAnswerDraft.multiChoice(optionIds: <int>[3, 1]),
      );
      final yesNoPayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[2],
        draft: const ScaleAnswerDraft.singleChoice(optionId: 20),
      );
      final textPayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[3],
        draft: const ScaleAnswerDraft.text(textValue: '  无法入睡  '),
      );
      final timePayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[4],
        draft: const ScaleAnswerDraft.time(timeValue: '23:05'),
      );
      final durationPayload = ScaleAnswerCodec.toRequestAnswer(
        question: questions[5],
        draft: const ScaleAnswerDraft.duration(durationMinutes: 95),
      );

      expect(singlePayload, <String, dynamic>{'optionId': 10});
      expect(multiPayload, <String, dynamic>{'optionIds': <int>[1, 3]});
      expect(yesNoPayload, <String, dynamic>{'optionId': 20});
      expect(textPayload, <String, dynamic>{'text': '无法入睡'});
      expect(timePayload, <String, dynamic>{'value': '23:05'});
      expect(durationPayload, <String, dynamic>{'value': '95m'});
    });

    test('isAnswered follows question type validation rules', () {
      expect(
        ScaleAnswerCodec.isAnswered(
          question: questions[0],
          draft: const ScaleAnswerDraft.singleChoice(optionId: 1),
        ),
        isTrue,
      );
      expect(
        ScaleAnswerCodec.isAnswered(
          question: questions[1],
          draft: const ScaleAnswerDraft.multiChoice(optionIds: <int>[]),
        ),
        isFalse,
      );
      expect(
        ScaleAnswerCodec.isAnswered(
          question: questions[3],
          draft: const ScaleAnswerDraft.text(textValue: '   '),
        ),
        isFalse,
      );
      expect(
        ScaleAnswerCodec.isAnswered(
          question: questions[4],
          draft: const ScaleAnswerDraft.time(timeValue: '99:99'),
        ),
        isFalse,
      );
      expect(
        ScaleAnswerCodec.isAnswered(
          question: questions[5],
          draft: const ScaleAnswerDraft.duration(durationMinutes: 0),
        ),
        isFalse,
      );
    });
  });
}

ScaleQuestion _question({
  required int id,
  required ScaleQuestionType type,
}) {
  return ScaleQuestion(
    questionId: id,
    questionKey: 'q$id',
    orderNo: id,
    type: type,
    dimension: 'total',
    required: true,
    scorable: true,
    reverseScored: false,
    stem: 'question-$id',
    options: const <ScaleQuestionOption>[
      ScaleQuestionOption(optionId: 1, optionKey: 'a', orderNo: 1, label: 'A'),
      ScaleQuestionOption(optionId: 2, optionKey: 'b', orderNo: 2, label: 'B'),
      ScaleQuestionOption(optionId: 3, optionKey: 'c', orderNo: 3, label: 'C'),
      ScaleQuestionOption(optionId: 10, optionKey: 'x', orderNo: 4, label: 'X'),
      ScaleQuestionOption(optionId: 20, optionKey: 'y', orderNo: 5, label: 'Y'),
    ],
  );
}
