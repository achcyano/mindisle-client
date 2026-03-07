final class DoctorScaleTrendPoint {
  const DoctorScaleTrendPoint({
    required this.scaleCode,
    required this.scaleName,
    required this.totalScore,
    required this.submittedAt,
  });

  final String scaleCode;
  final String scaleName;
  final double? totalScore;
  final DateTime? submittedAt;
}

final class DoctorAssessmentReport {
  const DoctorAssessmentReport({
    required this.summary,
    required this.polished,
  });

  final String summary;
  final bool polished;
}
