import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

ScalePublishStatus scalePublishStatusFromWire(String? raw) {
  return switch ((raw ?? '').toUpperCase()) {
    'DRAFT' => ScalePublishStatus.draft,
    'PUBLISHED' => ScalePublishStatus.published,
    'ARCHIVED' => ScalePublishStatus.archived,
    _ => ScalePublishStatus.unknown,
  };
}

ScaleSessionStatus scaleSessionStatusFromWire(String? raw) {
  return switch ((raw ?? '').toUpperCase()) {
    'IN_PROGRESS' => ScaleSessionStatus.inProgress,
    'SUBMITTED' => ScaleSessionStatus.submitted,
    'ABANDONED' => ScaleSessionStatus.abandoned,
    _ => ScaleSessionStatus.unknown,
  };
}

ScaleQuestionType scaleQuestionTypeFromWire(String? raw) {
  return switch ((raw ?? '').toUpperCase()) {
    'SINGLE_CHOICE' => ScaleQuestionType.singleChoice,
    'MULTI_CHOICE' => ScaleQuestionType.multiChoice,
    'YES_NO' => ScaleQuestionType.yesNo,
    'TEXT' => ScaleQuestionType.text,
    'TIME' => ScaleQuestionType.time,
    'DURATION' => ScaleQuestionType.duration,
    _ => ScaleQuestionType.unknown,
  };
}

final class ScaleSummaryDto {
  const ScaleSummaryDto({
    required this.scaleId,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    this.versionId,
    this.version,
  });

  factory ScaleSummaryDto.fromJson(Map<String, dynamic> json) {
    return ScaleSummaryDto(
      scaleId: _toInt(json['scaleId']) ?? _toInt(json['id']) ?? 0,
      code: _toNonEmptyString(json['code']) ?? '',
      name: _toNonEmptyString(json['name']) ?? '',
      description: _toNonEmptyString(json['description']) ?? '',
      status: scalePublishStatusFromWire(json['status'] as String?),
      versionId: _toInt(json['versionId']),
      version: _toInt(json['version']),
    );
  }

  final int scaleId;
  final String code;
  final String name;
  final String description;
  final ScalePublishStatus status;
  final int? versionId;
  final int? version;

  ScaleSummary toDomain() {
    return ScaleSummary(
      scaleId: scaleId,
      code: code,
      name: name,
      description: description,
      status: status,
      versionId: versionId,
      version: version,
    );
  }
}

final class ScaleScoreRangeDto {
  const ScaleScoreRangeDto({this.min, this.max});

  factory ScaleScoreRangeDto.fromJson(Map<String, dynamic> json) {
    return ScaleScoreRangeDto(
      min: _toDouble(json['min']),
      max: _toDouble(json['max']),
    );
  }

  final double? min;
  final double? max;

  ScaleScoreRange toDomain() {
    return ScaleScoreRange(min: min, max: max);
  }
}

final class ScaleDimensionDefinitionDto {
  const ScaleDimensionDefinitionDto({
    required this.key,
    required this.name,
    required this.description,
    this.scoreRange,
    this.interpretationHint,
  });

  factory ScaleDimensionDefinitionDto.fromJson(Map<String, dynamic> json) {
    final scoreRangeRaw = json['scoreRange'];
    return ScaleDimensionDefinitionDto(
      key: _toNonEmptyString(json['key']) ?? '',
      name: _toNonEmptyString(json['name']) ?? '',
      description: _toNonEmptyString(json['description']) ?? '',
      scoreRange: scoreRangeRaw is Map
          ? ScaleScoreRangeDto.fromJson(
              Map<String, dynamic>.from(scoreRangeRaw),
            )
          : null,
      interpretationHint: _toNonEmptyString(json['interpretationHint']),
    );
  }

  final String key;
  final String name;
  final String description;
  final ScaleScoreRangeDto? scoreRange;
  final String? interpretationHint;

  ScaleDimensionDefinition toDomain() {
    return ScaleDimensionDefinition(
      key: key,
      name: name,
      description: description,
      scoreRange: scoreRange?.toDomain(),
      interpretationHint: interpretationHint,
    );
  }
}

final class ScaleQuestionOptionDto {
  const ScaleQuestionOptionDto({
    this.optionId,
    this.optionKey,
    required this.orderNo,
    required this.label,
    this.scoreValue,
  });

  factory ScaleQuestionOptionDto.fromJson(Map<String, dynamic> json) {
    return ScaleQuestionOptionDto(
      optionId: _toInt(json['optionId']) ?? _toInt(json['id']),
      optionKey:
          _toNonEmptyString(json['optionKey']) ??
          _toNonEmptyString(json['key']),
      orderNo: _toInt(json['orderNo']) ?? 0,
      label: _toNonEmptyString(json['label']) ?? '',
      scoreValue: _toDouble(json['scoreValue']),
    );
  }

  final int? optionId;
  final String? optionKey;
  final int orderNo;
  final String label;
  final double? scoreValue;

  ScaleQuestionOption toDomain() {
    return ScaleQuestionOption(
      optionId: optionId,
      optionKey: optionKey,
      orderNo: orderNo,
      label: label,
      scoreValue: scoreValue,
    );
  }
}

final class ScaleQuestionDto {
  const ScaleQuestionDto({
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
    this.options = const <ScaleQuestionOptionDto>[],
  });

  factory ScaleQuestionDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <ScaleQuestionOptionDto>[
      if (rawOptions is List)
        for (final raw in rawOptions)
          if (raw is Map)
            ScaleQuestionOptionDto.fromJson(Map<String, dynamic>.from(raw)),
    ]..sort((a, b) => a.orderNo.compareTo(b.orderNo));

    return ScaleQuestionDto(
      questionId: _toInt(json['questionId']) ?? _toInt(json['id']) ?? 0,
      questionKey:
          _toNonEmptyString(json['questionKey']) ??
          _toNonEmptyString(json['key']) ??
          '',
      orderNo: _toInt(json['orderNo']) ?? 0,
      type: scaleQuestionTypeFromWire(json['type'] as String?),
      dimension: _toNonEmptyString(json['dimension']) ?? '',
      required: _toBool(json['required']),
      scorable: _toBool(json['scorable']),
      reverseScored: _toBool(json['reverseScored']),
      stem: _toNonEmptyString(json['stem']) ?? '',
      note: _toNonEmptyString(json['note']),
      optionSetCode: _toNonEmptyString(json['optionSetCode']),
      options: options,
    );
  }

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
  final List<ScaleQuestionOptionDto> options;

  ScaleQuestion toDomain() {
    return ScaleQuestion(
      questionId: questionId,
      questionKey: questionKey,
      orderNo: orderNo,
      type: type,
      dimension: dimension,
      required: required,
      scorable: scorable,
      reverseScored: reverseScored,
      stem: stem,
      note: note,
      optionSetCode: optionSetCode,
      options: options.map((it) => it.toDomain()).toList(growable: false),
    );
  }
}

final class ScaleDetailDto {
  const ScaleDetailDto({
    required this.scaleId,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    this.versionId,
    this.version,
    this.config = const <String, dynamic>{},
    this.dimensions = const <ScaleDimensionDefinitionDto>[],
    this.questions = const <ScaleQuestionDto>[],
  });

  factory ScaleDetailDto.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['config'];
    final rawDimensions = json['dimensions'];
    final rawQuestions = json['questions'];

    final questions = <ScaleQuestionDto>[
      if (rawQuestions is List)
        for (final raw in rawQuestions)
          if (raw is Map)
            ScaleQuestionDto.fromJson(Map<String, dynamic>.from(raw)),
    ]..sort((a, b) => a.orderNo.compareTo(b.orderNo));

    return ScaleDetailDto(
      scaleId: _toInt(json['scaleId']) ?? _toInt(json['id']) ?? 0,
      code: _toNonEmptyString(json['code']) ?? '',
      name: _toNonEmptyString(json['name']) ?? '',
      description: _toNonEmptyString(json['description']) ?? '',
      status: scalePublishStatusFromWire(json['status'] as String?),
      versionId: _toInt(json['versionId']),
      version: _toInt(json['version']),
      config: rawConfig is Map
          ? Map<String, dynamic>.from(rawConfig)
          : const <String, dynamic>{},
      dimensions: <ScaleDimensionDefinitionDto>[
        if (rawDimensions is List)
          for (final raw in rawDimensions)
            if (raw is Map)
              ScaleDimensionDefinitionDto.fromJson(
                Map<String, dynamic>.from(raw),
              ),
      ],
      questions: questions,
    );
  }

  final int scaleId;
  final String code;
  final String name;
  final String description;
  final ScalePublishStatus status;
  final int? versionId;
  final int? version;
  final Map<String, dynamic> config;
  final List<ScaleDimensionDefinitionDto> dimensions;
  final List<ScaleQuestionDto> questions;

  ScaleDetail toDomain() {
    return ScaleDetail(
      scaleId: scaleId,
      code: code,
      name: name,
      description: description,
      status: status,
      versionId: versionId,
      version: version,
      config: config,
      dimensions: dimensions.map((it) => it.toDomain()).toList(growable: false),
      questions: questions.map((it) => it.toDomain()).toList(growable: false),
    );
  }
}

final class ScaleSessionDto {
  const ScaleSessionDto({
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

  factory ScaleSessionDto.fromJson(Map<String, dynamic> json) {
    return ScaleSessionDto(
      sessionId: _toInt(json['sessionId']) ?? _toInt(json['id']) ?? 0,
      scaleId: _toInt(json['scaleId']) ?? 0,
      scaleCode: _toNonEmptyString(json['scaleCode']) ?? '',
      scaleName: _toNonEmptyString(json['scaleName']) ?? '',
      versionId: _toInt(json['versionId']),
      version: _toInt(json['version']),
      status: scaleSessionStatusFromWire(json['status'] as String?),
      progress: _toInt(json['progress']) ?? 0,
      startedAt: _parseDateTime(json['startedAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      submittedAt: _parseDateTime(json['submittedAt']),
    );
  }

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

  ScaleSession toDomain() {
    return ScaleSession(
      sessionId: sessionId,
      scaleId: scaleId,
      scaleCode: scaleCode,
      scaleName: scaleName,
      versionId: versionId,
      version: version,
      status: status,
      progress: progress,
      startedAt: startedAt,
      updatedAt: updatedAt,
      submittedAt: submittedAt,
    );
  }
}

final class ScaleCreateSessionResultDto {
  const ScaleCreateSessionResultDto({
    required this.created,
    required this.session,
  });

  factory ScaleCreateSessionResultDto.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    return ScaleCreateSessionResultDto(
      created: _toBool(json['created']),
      session: rawSession is Map
          ? ScaleSessionDto.fromJson(Map<String, dynamic>.from(rawSession))
          : ScaleSessionDto.fromJson(json),
    );
  }

  final bool created;
  final ScaleSessionDto session;

  ScaleCreateSessionResult toDomain() {
    return ScaleCreateSessionResult(
      created: created,
      session: session.toDomain(),
    );
  }
}

final class ScaleAnswerDto {
  const ScaleAnswerDto({
    required this.questionId,
    required this.rawAnswer,
    this.selectedOptionId,
    this.selectedOptionIds = const <int>[],
    this.textValue,
  });

  factory ScaleAnswerDto.fromJson(Map<String, dynamic> json) {
    final questionId = _toInt(json['questionId']) ?? _toInt(json['id']) ?? 0;
    final rawAnswer = json.containsKey('answer')
        ? json['answer']
        : (json['value'] ?? json);
    final selectedOptionId =
        _extractOptionId(rawAnswer) ?? _toInt(json['optionId']);
    final selectedOptionIds = _extractOptionIds(rawAnswer).isNotEmpty
        ? _extractOptionIds(rawAnswer)
        : _extractOptionIds(json['optionIds']);
    final textValue =
        _extractText(rawAnswer) ?? _toNonEmptyString(json['text']);

    return ScaleAnswerDto(
      questionId: questionId,
      rawAnswer: rawAnswer,
      selectedOptionId: selectedOptionId,
      selectedOptionIds: selectedOptionIds,
      textValue: textValue,
    );
  }

  final int questionId;
  final Object? rawAnswer;
  final int? selectedOptionId;
  final List<int> selectedOptionIds;
  final String? textValue;

  ScaleAnswer toDomain() {
    return ScaleAnswer(
      questionId: questionId,
      rawAnswer: rawAnswer,
      selectedOptionId: selectedOptionId,
      selectedOptionIds: selectedOptionIds,
      textValue: textValue,
    );
  }
}

final class ScaleSessionDetailDto {
  const ScaleSessionDetailDto({
    required this.session,
    this.answers = const <ScaleAnswerDto>[],
    this.unansweredRequiredQuestionIds = const <int>[],
  });

  factory ScaleSessionDetailDto.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    final rawAnswers = json['answers'];
    final rawUnanswered = json['unansweredRequiredQuestionIds'];

    return ScaleSessionDetailDto(
      session: rawSession is Map
          ? ScaleSessionDto.fromJson(Map<String, dynamic>.from(rawSession))
          : ScaleSessionDto.fromJson(json),
      answers: <ScaleAnswerDto>[
        if (rawAnswers is List)
          for (final raw in rawAnswers)
            if (raw is Map)
              ScaleAnswerDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      unansweredRequiredQuestionIds: <int>[
        if (rawUnanswered is List)
          for (final raw in rawUnanswered)
            if (_toInt(raw) != null) _toInt(raw)!,
      ],
    );
  }

  final ScaleSessionDto session;
  final List<ScaleAnswerDto> answers;
  final List<int> unansweredRequiredQuestionIds;

  ScaleSessionDetail toDomain() {
    return ScaleSessionDetail(
      session: session.toDomain(),
      answers: answers.map((it) => it.toDomain()).toList(growable: false),
      unansweredRequiredQuestionIds: unansweredRequiredQuestionIds,
    );
  }
}

final class ScaleDimensionResultDto {
  const ScaleDimensionResultDto({
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

  factory ScaleDimensionResultDto.fromJson(Map<String, dynamic> json) {
    final rawExtra = json['extraMetrics'];
    return ScaleDimensionResultDto(
      dimensionKey: _toNonEmptyString(json['dimensionKey']) ?? '',
      dimensionName: _toNonEmptyString(json['dimensionName']) ?? '',
      rawScore: _toDouble(json['rawScore']),
      averageScore: _toDouble(json['averageScore']),
      standardScore: _toDouble(json['standardScore']),
      levelCode: _toNonEmptyString(json['levelCode']),
      levelName: _toNonEmptyString(json['levelName']),
      interpretation: _toNonEmptyString(json['interpretation']),
      extraMetrics: rawExtra is Map
          ? Map<String, dynamic>.from(rawExtra)
          : const <String, dynamic>{},
    );
  }

  final String dimensionKey;
  final String dimensionName;
  final double? rawScore;
  final double? averageScore;
  final double? standardScore;
  final String? levelCode;
  final String? levelName;
  final String? interpretation;
  final Map<String, dynamic> extraMetrics;

  ScaleDimensionResult toDomain() {
    return ScaleDimensionResult(
      dimensionKey: dimensionKey,
      dimensionName: dimensionName,
      rawScore: rawScore,
      averageScore: averageScore,
      standardScore: standardScore,
      levelCode: levelCode,
      levelName: levelName,
      interpretation: interpretation,
      extraMetrics: extraMetrics,
    );
  }
}

final class ScaleResultDto {
  const ScaleResultDto({
    required this.sessionId,
    this.totalScore,
    this.dimensionScores = const <String, double>{},
    this.dimensionResults = const <ScaleDimensionResultDto>[],
    this.overallMetrics = const <String, dynamic>{},
    this.resultFlags = const <String>[],
    this.bandLevelCode,
    this.bandLevelName,
    this.resultText,
    this.computedAt,
  });

  factory ScaleResultDto.fromJson(Map<String, dynamic> json) {
    final rawDimensionScores = json['dimensionScores'];
    final rawDimensionResults = json['dimensionResults'];
    final rawOverallMetrics = json['overallMetrics'];
    final rawResultFlags = json['resultFlags'];
    final dimensionScores = <String, double>{};
    if (rawDimensionScores is Map) {
      rawDimensionScores.forEach((key, value) {
        final parsed = _toDouble(value);
        if (key is String && parsed != null) {
          dimensionScores[key] = parsed;
        }
      });
    }

    return ScaleResultDto(
      sessionId: _toInt(json['sessionId']) ?? 0,
      totalScore: _toDouble(json['totalScore']),
      dimensionScores: dimensionScores,
      dimensionResults: <ScaleDimensionResultDto>[
        if (rawDimensionResults is List)
          for (final raw in rawDimensionResults)
            if (raw is Map)
              ScaleDimensionResultDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      overallMetrics: rawOverallMetrics is Map
          ? Map<String, dynamic>.from(rawOverallMetrics)
          : const <String, dynamic>{},
      resultFlags: <String>[
        if (rawResultFlags is List)
          for (final raw in rawResultFlags)
            if (raw is String && raw.trim().isNotEmpty) raw,
      ],
      bandLevelCode: _toNonEmptyString(json['bandLevelCode']),
      bandLevelName: _toNonEmptyString(json['bandLevelName']),
      resultText: _toNonEmptyString(json['resultText']),
      computedAt: _parseDateTime(json['computedAt']),
    );
  }

  final int sessionId;
  final double? totalScore;
  final Map<String, double> dimensionScores;
  final List<ScaleDimensionResultDto> dimensionResults;
  final Map<String, dynamic> overallMetrics;
  final List<String> resultFlags;
  final String? bandLevelCode;
  final String? bandLevelName;
  final String? resultText;
  final DateTime? computedAt;

  ScaleResult toDomain() {
    return ScaleResult(
      sessionId: sessionId,
      totalScore: totalScore,
      dimensionScores: dimensionScores,
      dimensionResults: dimensionResults
          .map((it) => it.toDomain())
          .toList(growable: false),
      overallMetrics: overallMetrics,
      resultFlags: resultFlags,
      bandLevelCode: bandLevelCode,
      bandLevelName: bandLevelName,
      resultText: resultText,
      computedAt: computedAt,
    );
  }
}

final class ScaleHistoryItemDto {
  const ScaleHistoryItemDto({
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

  factory ScaleHistoryItemDto.fromJson(Map<String, dynamic> json) {
    return ScaleHistoryItemDto(
      sessionId: _toInt(json['sessionId']) ?? 0,
      scaleId: _toInt(json['scaleId']) ?? 0,
      scaleCode: _toNonEmptyString(json['scaleCode']) ?? '',
      scaleName: _toNonEmptyString(json['scaleName']) ?? '',
      versionId: _toInt(json['versionId']),
      version: _toInt(json['version']),
      progress: _toInt(json['progress']),
      totalScore: _toDouble(json['totalScore']),
      submittedAt: _parseDateTime(json['submittedAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

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

  ScaleHistoryItem toDomain() {
    return ScaleHistoryItem(
      sessionId: sessionId,
      scaleId: scaleId,
      scaleCode: scaleCode,
      scaleName: scaleName,
      versionId: versionId,
      version: version,
      progress: progress,
      totalScore: totalScore,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
    );
  }
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

String? _toNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _extractOptionId(Object? raw) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return _toInt(map['optionId']) ?? _toInt(map['id']);
  }
  return _toInt(raw);
}

List<int> _extractOptionIds(Object? raw) {
  if (raw is List) {
    return raw.map(_toInt).whereType<int>().toList(growable: false);
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final nested = map['optionIds'];
    if (nested is List) {
      return nested.map(_toInt).whereType<int>().toList(growable: false);
    }
  }
  return const <int>[];
}

String? _extractText(Object? raw) {
  if (raw is String) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return _toNonEmptyString(map['text']) ??
        _toNonEmptyString(map['value']) ??
        _toNonEmptyString(map['answer']);
  }
  return null;
}
