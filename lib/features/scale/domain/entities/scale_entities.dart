enum ScalePublishStatus { draft, published, archived, unknown }

enum ScaleSessionStatus { inProgress, submitted, abandoned, unknown }

enum ScaleQuestionType {
  singleChoice,
  multiChoice,
  yesNo,
  text,
  time,
  duration,
  unknown,
}

enum ScaleAssistEventType { meta, delta, done, error, unknown }

final class ScaleSummary {
  const ScaleSummary({
    required this.scaleId,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    this.versionId,
    this.version,
  });

  final int scaleId;
  final String code;
  final String name;
  final String description;
  final ScalePublishStatus status;
  final int? versionId;
  final int? version;
}

final class ScaleScoreRange {
  const ScaleScoreRange({this.min, this.max});

  final double? min;
  final double? max;
}

final class ScaleDimensionDefinition {
  const ScaleDimensionDefinition({
    required this.key,
    required this.name,
    required this.description,
    this.scoreRange,
    this.interpretationHint,
  });

  final String key;
  final String name;
  final String description;
  final ScaleScoreRange? scoreRange;
  final String? interpretationHint;
}

final class ScaleQuestionOption {
  const ScaleQuestionOption({
    this.optionId,
    this.optionKey,
    required this.orderNo,
    required this.label,
    this.scoreValue,
  });

  final int? optionId;
  final String? optionKey;
  final int orderNo;
  final String label;
  final double? scoreValue;
}

final class ScaleQuestion {
  const ScaleQuestion({
    required this.questionId,
    required this.questionKey,
    required this.orderNo,
    required this.type,
    required this.dimension,
    required this.required,
    required this.scorable,
    required this.reverseScored,
    required this.stem,
    this.note,
    this.optionSetCode,
    this.options = const <ScaleQuestionOption>[],
  });

  final int questionId;
  final String questionKey;
  final int orderNo;
  final ScaleQuestionType type;
  final String dimension;
  final bool required;
  final bool scorable;
  final bool reverseScored;
  final String stem;
  final String? note;
  final String? optionSetCode;
  final List<ScaleQuestionOption> options;
}

final class ScaleDetail {
  const ScaleDetail({
    required this.scaleId,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    this.versionId,
    this.version,
    this.config = const <String, dynamic>{},
    this.dimensions = const <ScaleDimensionDefinition>[],
    this.questions = const <ScaleQuestion>[],
  });

  final int scaleId;
  final String code;
  final String name;
  final String description;
  final ScalePublishStatus status;
  final int? versionId;
  final int? version;
  final Map<String, dynamic> config;
  final List<ScaleDimensionDefinition> dimensions;
  final List<ScaleQuestion> questions;
}

final class ScaleSession {
  const ScaleSession({
    required this.sessionId,
    required this.scaleId,
    required this.scaleCode,
    required this.scaleName,
    this.versionId,
    this.version,
    required this.status,
    required this.progress,
    this.startedAt,
    this.updatedAt,
    this.submittedAt,
  });

  final int sessionId;
  final int scaleId;
  final String scaleCode;
  final String scaleName;
  final int? versionId;
  final int? version;
  final ScaleSessionStatus status;
  final int progress;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
}

final class ScaleCreateSessionResult {
  const ScaleCreateSessionResult({
    required this.created,
    required this.session,
  });

  final bool created;
  final ScaleSession session;
}

final class ScaleAnswer {
  const ScaleAnswer({
    required this.questionId,
    required this.rawAnswer,
    this.selectedOptionId,
    this.selectedOptionIds = const <int>[],
    this.textValue,
  });

  final int questionId;
  final Object? rawAnswer;
  final int? selectedOptionId;
  final List<int> selectedOptionIds;
  final String? textValue;
}

final class ScaleSessionDetail {
  const ScaleSessionDetail({
    required this.session,
    this.answers = const <ScaleAnswer>[],
    this.unansweredRequiredQuestionIds = const <int>[],
  });

  final ScaleSession session;
  final List<ScaleAnswer> answers;
  final List<int> unansweredRequiredQuestionIds;
}

final class ScaleDimensionResult {
  const ScaleDimensionResult({
    required this.dimensionKey,
    required this.dimensionName,
    this.rawScore,
    this.averageScore,
    this.standardScore,
    this.levelCode,
    this.levelName,
    this.interpretation,
    this.extraMetrics = const <String, dynamic>{},
  });

  final String dimensionKey;
  final String dimensionName;
  final double? rawScore;
  final double? averageScore;
  final double? standardScore;
  final String? levelCode;
  final String? levelName;
  final String? interpretation;
  final Map<String, dynamic> extraMetrics;
}

final class ScaleResult {
  const ScaleResult({
    required this.sessionId,
    this.totalScore,
    this.dimensionScores = const <String, double>{},
    this.dimensionResults = const <ScaleDimensionResult>[],
    this.overallMetrics = const <String, dynamic>{},
    this.resultFlags = const <String>[],
    this.bandLevelCode,
    this.bandLevelName,
    this.resultText,
    this.computedAt,
  });

  final int sessionId;
  final double? totalScore;
  final Map<String, double> dimensionScores;
  final List<ScaleDimensionResult> dimensionResults;
  final Map<String, dynamic> overallMetrics;
  final List<String> resultFlags;
  final String? bandLevelCode;
  final String? bandLevelName;
  final String? resultText;
  final DateTime? computedAt;
}

final class ScaleHistoryItem {
  const ScaleHistoryItem({
    required this.sessionId,
    required this.scaleId,
    required this.scaleCode,
    required this.scaleName,
    this.versionId,
    this.version,
    this.progress,
    this.totalScore,
    this.submittedAt,
    this.updatedAt,
  });

  final int sessionId;
  final int scaleId;
  final String scaleCode;
  final String scaleName;
  final int? versionId;
  final int? version;
  final int? progress;
  final double? totalScore;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
}

final class ScaleAssistEvent {
  const ScaleAssistEvent({
    required this.type,
    this.eventId,
    this.eventName,
    this.generationId,
    this.delta,
    this.errorCode,
    this.errorMessage,
  });

  final ScaleAssistEventType type;
  final String? eventId;
  final String? eventName;
  final String? generationId;
  final String? delta;
  final int? errorCode;
  final String? errorMessage;
}
