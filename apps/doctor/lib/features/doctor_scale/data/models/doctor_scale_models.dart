import 'dart:convert';

import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

DoctorAssessmentReport decodeDoctorAssessmentReport(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorAssessmentReport(
    summary: (map['summary'] as String?) ?? (map['report'] as String?) ?? '',
    polished: map['polished'] == true,
  );
}

DoctorAssessmentReportSummary decodeDoctorLatestAssessmentReport(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return _decodeAssessmentReportSummary(map);
}

DoctorAssessmentReportListResult decodeDoctorAssessmentReports(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'] ?? map['reports'];
  return DoctorAssessmentReportListResult(
    items: [
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map)
            _decodeAssessmentReportSummary(Map<String, dynamic>.from(raw)),
    ],
    nextCursor:
        _toCursorString(map['nextCursor']) ?? _toCursorString(map['cursor']),
  );
}

DoctorAssessmentReportDetail decodeDoctorAssessmentReportDetail(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawAnswers = map['answers'] ?? map['answerRecords'];
  final rawDimensionResults = map['dimensionResults'];
  final rawDimensionScores = map['dimensionScores'];

  return DoctorAssessmentReportDetail(
    reportId:
        _toInt(map['reportId']) ??
        _toInt(map['id']) ??
        _toInt(map['assessmentReportId']) ??
        0,
    generatedAt:
        _toDateTime(map['generatedAt']) ??
        _toDateTime(map['createdAt']) ??
        _toDateTime(map['updatedAt']),
    summary:
        _toNonEmptyString(map['summary']) ??
        _toNonEmptyString(map['analysis']) ??
        _toNonEmptyString(map['report']),
    dimensionScores: _decodeDimensionScores(rawDimensionScores),
    dimensionResults: [
      if (rawDimensionResults is List)
        for (final raw in rawDimensionResults)
          if (raw is Map)
            _decodeDimensionResult(Map<String, dynamic>.from(raw)),
    ],
    answerRecords: [
      if (rawAnswers is List)
        for (final raw in rawAnswers)
          if (raw is Map) _decodeAnswerRecord(Map<String, dynamic>.from(raw)),
    ],
  );
}

DoctorScaleAnswerRecordListResult decodeDoctorScaleAnswerRecords(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'] ?? map['records'] ?? map['history'];
  return DoctorScaleAnswerRecordListResult(
    items: [
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map)
            _decodeScaleAnswerRecord(Map<String, dynamic>.from(raw)),
    ],
    nextCursor:
        _toCursorString(map['nextCursor']) ?? _toCursorString(map['cursor']),
  );
}

DoctorScaleSessionResult decodeDoctorScaleSessionResult(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawDimensionScores = map['dimensionScores'];
  final rawDimensionResults = map['dimensionResults'];
  final rawResultFlags = map['resultFlags'];
  final rawOverallMetrics = map['overallMetrics'];

  return DoctorScaleSessionResult(
    sessionId: _toInt(map['sessionId']) ?? 0,
    totalScore: _toDouble(map['totalScore']),
    dimensionScores: _decodeDimensionScores(rawDimensionScores),
    dimensionResults: [
      if (rawDimensionResults is List)
        for (final raw in rawDimensionResults)
          if (raw is Map)
            _decodeDimensionResult(Map<String, dynamic>.from(raw)),
    ],
    overallMetrics: rawOverallMetrics is Map
        ? Map<String, dynamic>.from(rawOverallMetrics)
        : const <String, dynamic>{},
    resultFlags: [
      if (rawResultFlags is List)
        for (final raw in rawResultFlags)
          if (raw is String && raw.trim().isNotEmpty) raw,
    ],
    bandLevelCode: _toNonEmptyString(map['bandLevelCode']),
    bandLevelName: _toNonEmptyString(map['bandLevelName']),
    resultText: _toNonEmptyString(map['resultText']),
    computedAt:
        _toDateTime(map['computedAt']) ??
        _toDateTime(map['createdAt']) ??
        _toDateTime(map['updatedAt']),
  );
}

DoctorAssessmentReportSummary _decodeAssessmentReportSummary(
  Map<String, dynamic> map,
) {
  return DoctorAssessmentReportSummary(
    reportId:
        _toInt(map['reportId']) ??
        _toInt(map['id']) ??
        _toInt(map['assessmentReportId']) ??
        0,
    generatedAt:
        _toDateTime(map['generatedAt']) ??
        _toDateTime(map['createdAt']) ??
        _toDateTime(map['updatedAt']),
    scaleCode: _toNonEmptyString(map['scaleCode']),
    scaleName: _toNonEmptyString(map['scaleName']),
    summary:
        _toNonEmptyString(map['summary']) ??
        _toNonEmptyString(map['analysis']) ??
        _toNonEmptyString(map['report']),
    totalScore: _toDouble(map['totalScore']),
  );
}

Map<String, double> _decodeDimensionScores(Object? raw) {
  if (raw is! Map) return const <String, double>{};
  final output = <String, double>{};
  raw.forEach((key, value) {
    final parsed = _toDouble(value);
    if (key is String && parsed != null) {
      output[key] = parsed;
    }
  });
  return output;
}

DoctorAssessmentDimensionResult _decodeDimensionResult(
  Map<String, dynamic> raw,
) {
  final rawExtraMetrics = raw['extraMetrics'];
  return DoctorAssessmentDimensionResult(
    dimensionKey: _toNonEmptyString(raw['dimensionKey']) ?? '',
    dimensionName:
        _toNonEmptyString(raw['dimensionName']) ??
        _toNonEmptyString(raw['dimensionKey']) ??
        '',
    rawScore: _toDouble(raw['rawScore']),
    averageScore: _toDouble(raw['averageScore']),
    standardScore: _toDouble(raw['standardScore']),
    levelCode: _toNonEmptyString(raw['levelCode']),
    levelName: _toNonEmptyString(raw['levelName']),
    interpretation: _toNonEmptyString(raw['interpretation']),
    extraMetrics: rawExtraMetrics is Map
        ? Map<String, dynamic>.from(rawExtraMetrics)
        : const <String, dynamic>{},
  );
}

DoctorAssessmentAnswerRecord _decodeAnswerRecord(Map<String, dynamic> raw) {
  final answerValue = raw['answerText'] ?? raw['answer'] ?? raw['value'];
  return DoctorAssessmentAnswerRecord(
    questionText:
        _toNonEmptyString(raw['questionText']) ??
        _toNonEmptyString(raw['questionTitle']) ??
        _toNonEmptyString(raw['question']) ??
        '未命名题目',
    answerText: _stringifyAnswer(answerValue),
    scaleName: _toNonEmptyString(raw['scaleName']),
    submittedAt:
        _toDateTime(raw['submittedAt']) ??
        _toDateTime(raw['answeredAt']) ??
        _toDateTime(raw['updatedAt']),
  );
}

DoctorScaleAnswerRecord _decodeScaleAnswerRecord(Map<String, dynamic> raw) {
  final normalizedMap = _asMap(raw['normalizedAnswer']);
  final sessionId =
      _toInt(raw['sessionId']) ?? _toInt(normalizedMap?['sessionId']);
  final dimensionScores = _decodeDimensionScores(
    raw['dimensionScores'] ?? normalizedMap?['dimensionScores'],
  );
  final dimensionResults = _decodeDimensionResults(
    raw['dimensionResults'] ?? normalizedMap?['dimensionResults'],
  );
  var rawEntries = _decodeRawEntries(raw['rawAnswer']);
  if (rawEntries.isEmpty) {
    rawEntries = _decodeRawEntries(raw['answers'] ?? raw['answerRecords']);
  }
  if (rawEntries.isEmpty) {
    final questionText =
        _toNonEmptyString(raw['questionText']) ??
        _toNonEmptyString(raw['questionTitle']) ??
        _toNonEmptyString(raw['question']) ??
        _toNonEmptyString(raw['stem']);
    if (questionText != null) {
      rawEntries = <DoctorScaleAnswerRawEntry>[
        DoctorScaleAnswerRawEntry(
          questionText: questionText,
          answerText: _stringifyAnswer(
            raw['answerText'] ?? raw['answer'] ?? raw['value'],
          ),
        ),
      ];
    }
  }

  return DoctorScaleAnswerRecord(
    recordId: _toInt(raw['recordId']) ?? _toInt(raw['id']) ?? sessionId ?? 0,
    sessionId: sessionId,
    reportId:
        _toInt(raw['reportId']) ??
        _toInt(raw['assessmentReportId']) ??
        _toInt(normalizedMap?['reportId']) ??
        _toInt(normalizedMap?['assessmentReportId']),
    scaleId: _toInt(raw['scaleId']) ?? _toInt(normalizedMap?['scaleId']),
    scaleCode:
        _toNonEmptyString(raw['scaleCode']) ??
        _toNonEmptyString(_asMap(raw['scale'])?['code']) ??
        _toNonEmptyString(normalizedMap?['scaleCode']),
    scaleName:
        _toNonEmptyString(raw['scaleName']) ??
        _toNonEmptyString(_asMap(raw['scale'])?['name']) ??
        _toNonEmptyString(normalizedMap?['scaleName']),
    versionId: _toInt(raw['versionId']) ?? _toInt(normalizedMap?['versionId']),
    version: _toInt(raw['version']) ?? _toInt(normalizedMap?['version']),
    progress: _toInt(raw['progress']) ?? _toInt(normalizedMap?['progress']),
    numericScore:
        _toDouble(raw['numericScore']) ??
        _toDouble(raw['totalScore']) ??
        _toDouble(normalizedMap?['numericScore']) ??
        _toDouble(normalizedMap?['totalScore']),
    answeredAt:
        _toDateTime(raw['answeredAt']) ??
        _toDateTime(raw['submittedAt']) ??
        _toDateTime(raw['updatedAt']) ??
        _toDateTime(raw['createdAt']),
    dimensionScores: dimensionScores,
    dimensionResults: dimensionResults,
    rawEntries: rawEntries,
  );
}

List<DoctorAssessmentDimensionResult> _decodeDimensionResults(Object? raw) {
  if (raw is! List) return const <DoctorAssessmentDimensionResult>[];
  return [
    for (final item in raw)
      if (item is Map) _decodeDimensionResult(Map<String, dynamic>.from(item)),
  ];
}

List<DoctorScaleAnswerRawEntry> _decodeRawEntries(Object? raw) {
  if (raw == null) return const <DoctorScaleAnswerRawEntry>[];
  if (raw is List) {
    return [for (final item in raw) ..._decodeRawEntries(item)];
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final nestedList =
        map['answers'] ?? map['items'] ?? map['records'] ?? map['questions'];
    if (nestedList is List && nestedList.isNotEmpty) {
      return _decodeRawEntries(nestedList);
    }

    final questionText =
        _toNonEmptyString(map['questionText']) ??
        _toNonEmptyString(map['questionTitle']) ??
        _toNonEmptyString(map['question']) ??
        _toNonEmptyString(map['stem']);
    if (questionText != null) {
      final answerValue =
          map['answerText'] ??
          map['answer'] ??
          map['value'] ??
          map['selected'] ??
          map['selectedOption'] ??
          map['selectedOptions'];
      return <DoctorScaleAnswerRawEntry>[
        DoctorScaleAnswerRawEntry(
          questionText: questionText,
          answerText: _stringifyAnswer(answerValue),
        ),
      ];
    }

    final entries = <DoctorScaleAnswerRawEntry>[];
    map.forEach((key, value) {
      if (_isMetadataKey(key)) return;
      entries.add(
        DoctorScaleAnswerRawEntry(
          questionText: key,
          answerText: _stringifyAnswer(value),
        ),
      );
    });
    if (entries.isNotEmpty) return entries;

    return <DoctorScaleAnswerRawEntry>[
      DoctorScaleAnswerRawEntry(
        questionText: '原始作答',
        answerText: _stringifyAnswer(map),
      ),
    ];
  }
  return <DoctorScaleAnswerRawEntry>[
    DoctorScaleAnswerRawEntry(
      questionText: '原始作答',
      answerText: _stringifyAnswer(raw),
    ),
  ];
}

Map<String, dynamic>? _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

String? _toCursorString(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) {
    return value.toInt().toString();
  }
  return null;
}

bool _isMetadataKey(String key) {
  const metadataKeys = <String>{
    'recordId',
    'id',
    'sessionId',
    'reportId',
    'assessmentReportId',
    'scaleId',
    'scaleCode',
    'scaleName',
    'answeredAt',
    'submittedAt',
    'updatedAt',
    'createdAt',
    'numericScore',
    'totalScore',
    'state',
    'status',
    'answers',
    'items',
    'records',
    'questions',
    'rawAnswer',
    'normalizedAnswer',
    'dimensionScores',
    'dimensionResults',
  };
  return metadataKeys.contains(key);
}

String _stringifyAnswer(Object? value) {
  if (value == null) return '--';
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '--' : trimmed;
  }
  if (value is num || value is bool) return value.toString();
  if (value is List) {
    final values = value
        .map(_stringifyAnswer)
        .where((it) => it != '--')
        .toList();
    return values.isEmpty ? '--' : values.join('、');
  }
  if (value is Map) {
    return jsonEncode(value);
  }
  return value.toString();
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _toNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
