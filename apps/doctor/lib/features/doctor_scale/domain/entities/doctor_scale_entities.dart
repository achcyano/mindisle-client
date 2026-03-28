final class DoctorAssessmentReport {
  const DoctorAssessmentReport({required this.summary, required this.polished});

  final String summary;
  final bool polished;
}

final class DoctorAssessmentReportListResult {
  const DoctorAssessmentReportListResult({
    required this.items,
    required this.nextCursor,
  });

  final List<DoctorAssessmentReportSummary> items;
  final String? nextCursor;
}

final class DoctorAssessmentReportSummary {
  const DoctorAssessmentReportSummary({
    required this.reportId,
    required this.generatedAt,
    this.scaleCode,
    this.scaleName,
    this.summary,
    this.totalScore,
  });

  final int reportId;
  final DateTime? generatedAt;
  final String? scaleCode;
  final String? scaleName;
  final String? summary;
  final double? totalScore;
}

final class DoctorAssessmentReportDetail {
  const DoctorAssessmentReportDetail({
    required this.reportId,
    required this.generatedAt,
    required this.summary,
    required this.dimensionScores,
    required this.dimensionResults,
    required this.answerRecords,
  });

  final int reportId;
  final DateTime? generatedAt;
  final String? summary;
  final Map<String, double> dimensionScores;
  final List<DoctorAssessmentDimensionResult> dimensionResults;
  final List<DoctorAssessmentAnswerRecord> answerRecords;
}

final class DoctorAssessmentDimensionResult {
  const DoctorAssessmentDimensionResult({
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

final class DoctorAssessmentAnswerRecord {
  const DoctorAssessmentAnswerRecord({
    required this.questionText,
    required this.answerText,
    this.scaleName,
    this.submittedAt,
  });

  final String questionText;
  final String answerText;
  final String? scaleName;
  final DateTime? submittedAt;
}

final class DoctorScaleAnswerRecordListResult {
  const DoctorScaleAnswerRecordListResult({
    required this.items,
    required this.nextCursor,
  });

  final List<DoctorScaleAnswerRecord> items;
  final String? nextCursor;
}

final class DoctorScaleAnswerRecord {
  const DoctorScaleAnswerRecord({
    required this.recordId,
    this.sessionId,
    this.reportId,
    this.scaleId,
    this.scaleCode,
    this.scaleName,
    this.versionId,
    this.version,
    this.progress,
    this.numericScore,
    this.answeredAt,
    this.dimensionScores = const <String, double>{},
    this.dimensionResults = const <DoctorAssessmentDimensionResult>[],
    this.rawEntries = const <DoctorScaleAnswerRawEntry>[],
  });

  final int recordId;
  final int? sessionId;
  final int? reportId;
  final int? scaleId;
  final String? scaleCode;
  final String? scaleName;
  final int? versionId;
  final int? version;
  final int? progress;
  final double? numericScore;
  final DateTime? answeredAt;
  final Map<String, double> dimensionScores;
  final List<DoctorAssessmentDimensionResult> dimensionResults;
  final List<DoctorScaleAnswerRawEntry> rawEntries;
}

final class DoctorScaleAnswerRawEntry {
  const DoctorScaleAnswerRawEntry({
    required this.questionText,
    required this.answerText,
  });

  final String questionText;
  final String answerText;
}

final class DoctorScaleSessionResult {
  const DoctorScaleSessionResult({
    required this.sessionId,
    this.totalScore,
    this.dimensionScores = const <String, double>{},
    this.dimensionResults = const <DoctorAssessmentDimensionResult>[],
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
  final List<DoctorAssessmentDimensionResult> dimensionResults;
  final Map<String, dynamic> overallMetrics;
  final List<String> resultFlags;
  final String? bandLevelCode;
  final String? bandLevelName;
  final String? resultText;
  final DateTime? computedAt;
}
