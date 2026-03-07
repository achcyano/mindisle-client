import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

List<DoctorScaleTrendPoint> decodeDoctorScaleTrends(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          DoctorScaleTrendPoint(
            scaleCode: (raw['scaleCode'] as String?) ?? '',
            scaleName: (raw['scaleName'] as String?) ?? '',
            totalScore: _toDouble(raw['totalScore']),
            submittedAt: _toDateTime(raw['submittedAt']) ?? _toDateTime(raw['updatedAt']),
          ),
  ];
}

DoctorAssessmentReport decodeDoctorAssessmentReport(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorAssessmentReport(
    summary: (map['summary'] as String?) ?? (map['report'] as String?) ?? '',
    polished: map['polished'] == true,
  );
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
