import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';

abstract final class ScaleAnswerCodec {
  static Map<int, ScaleAnswerDraft> fromSessionAnswers({
    required List<ScaleAnswer> answers,
    required List<ScaleQuestion> questions,
  }) {
    final questionById = <int, ScaleQuestion>{
      for (final question in questions) question.questionId: question,
    };
    final drafts = <int, ScaleAnswerDraft>{};

    for (final answer in answers) {
      final question = questionById[answer.questionId];
      if (question == null) continue;

      final draft = _fromAnswer(question: question, answer: answer);
      if (draft == null) continue;
      drafts[answer.questionId] = draft;
    }

    return drafts;
  }

  static ScaleAnswerDraft? _fromAnswer({
    required ScaleQuestion question,
    required ScaleAnswer answer,
  }) {
    switch (question.type) {
      case ScaleQuestionType.singleChoice:
      case ScaleQuestionType.yesNo:
        final optionId = answer.selectedOptionId;
        if (optionId == null) return null;
        return ScaleAnswerDraft.singleChoice(optionId: optionId);
      case ScaleQuestionType.multiChoice:
        final optionIds = answer.selectedOptionIds.isNotEmpty
            ? answer.selectedOptionIds
            : (answer.selectedOptionId == null
                  ? const <int>[]
                  : <int>[answer.selectedOptionId!]);
        if (optionIds.isEmpty) return null;
        return ScaleAnswerDraft.multiChoice(optionIds: _sortedUnique(optionIds));
      case ScaleQuestionType.text:
        final text = _extractText(answer);
        if (text == null || text.trim().isEmpty) return null;
        return ScaleAnswerDraft.text(textValue: text);
      case ScaleQuestionType.time:
        final value = _extractValue(answer);
        if (value == null || !_isValidTime(value)) return null;
        return ScaleAnswerDraft.time(timeValue: value);
      case ScaleQuestionType.duration:
        final value = _extractValue(answer);
        final minutes = _parseDurationMinutes(value);
        if (minutes == null) return null;
        return ScaleAnswerDraft.duration(durationMinutes: minutes);
      case ScaleQuestionType.unknown:
        return null;
    }
  }

  static Object? toRequestAnswer({
    required ScaleQuestion question,
    required ScaleAnswerDraft? draft,
  }) {
    if (draft == null) return null;

    switch (question.type) {
      case ScaleQuestionType.singleChoice:
      case ScaleQuestionType.yesNo:
        final optionId = draft.optionId;
        if (optionId == null) return null;
        return <String, dynamic>{'optionId': optionId};
      case ScaleQuestionType.multiChoice:
        final optionIds = _sortedUnique(draft.optionIds);
        if (optionIds.isEmpty) return null;
        return <String, dynamic>{'optionIds': optionIds};
      case ScaleQuestionType.text:
        final text = draft.textValue?.trim() ?? '';
        if (text.isEmpty) return null;
        return <String, dynamic>{'text': text};
      case ScaleQuestionType.time:
        final time = draft.timeValue?.trim() ?? '';
        if (!_isValidTime(time)) return null;
        return <String, dynamic>{'value': time};
      case ScaleQuestionType.duration:
        final minutes = draft.durationMinutes;
        if (minutes == null || minutes <= 0) return null;
        return <String, dynamic>{'value': '${minutes}m'};
      case ScaleQuestionType.unknown:
        return null;
    }
  }

  static bool isAnswered({
    required ScaleQuestion question,
    required ScaleAnswerDraft? draft,
  }) {
    if (draft == null) return false;

    switch (question.type) {
      case ScaleQuestionType.singleChoice:
      case ScaleQuestionType.yesNo:
        return draft.optionId != null;
      case ScaleQuestionType.multiChoice:
        return draft.optionIds.isNotEmpty;
      case ScaleQuestionType.text:
        return (draft.textValue?.trim().isNotEmpty ?? false);
      case ScaleQuestionType.time:
        return _isValidTime(draft.timeValue?.trim() ?? '');
      case ScaleQuestionType.duration:
        final minutes = draft.durationMinutes;
        return minutes != null && minutes > 0;
      case ScaleQuestionType.unknown:
        return false;
    }
  }

  static List<int> _sortedUnique(List<int> values) {
    final set = values.toSet().toList(growable: false);
    return List<int>.from(set)..sort();
  }

  static String? _extractText(ScaleAnswer answer) {
    final textValue = answer.textValue;
    if (textValue != null && textValue.trim().isNotEmpty) {
      return textValue.trim();
    }
    return _extractValue(answer);
  }

  static String? _extractValue(ScaleAnswer answer) {
    final raw = answer.rawAnswer;
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final value =
          map['value'] ?? map['text'] ?? map['answer'] ?? map['time'] ?? map['duration'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
  }

  static bool _isValidTime(String raw) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(raw);
    return match != null;
  }

  static int? _parseDurationMinutes(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;

    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;

    final minuteOnly = RegExp(r'^(\d+)\s*m$').firstMatch(value);
    if (minuteOnly != null) {
      return int.tryParse(minuteOnly.group(1)!);
    }

    final hourOnly = RegExp(r'^(\d+)\s*h$').firstMatch(value);
    if (hourOnly != null) {
      final hours = int.tryParse(hourOnly.group(1)!);
      if (hours == null) return null;
      return hours * 60;
    }

    final hourMinute = RegExp(r'^(\d+)\s*h\s*(\d+)\s*m$').firstMatch(value);
    if (hourMinute != null) {
      final hours = int.tryParse(hourMinute.group(1)!);
      final minutes = int.tryParse(hourMinute.group(2)!);
      if (hours == null || minutes == null) return null;
      return hours * 60 + minutes;
    }

    return null;
  }
}
