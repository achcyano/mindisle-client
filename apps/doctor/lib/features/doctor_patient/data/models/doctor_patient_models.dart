import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

DoctorPatientListResult decodeDoctorPatientList(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];

  return DoctorPatientListResult(
    items: [
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map) _decodePatient(Map<String, dynamic>.from(raw)),
    ],
    nextCursor: _toNonEmptyString(map['nextCursor']),
  );
}

DoctorPatient _decodePatient(Map<String, dynamic> map) {
  final grouping = map['grouping'];
  final groupingMap = grouping is Map ? Map<String, dynamic>.from(grouping) : null;
  return DoctorPatient(
    patientUserId: _toInt(map['patientUserId']) ?? _toInt(map['userId']) ?? 0,
    fullName: _toNonEmptyString(map['fullName']) ?? '',
    phone: _toNonEmptyString(map['phone']) ?? '',
    isAbnormal: _toBool(map['isAbnormal']),
    severityGroup: _toNonEmptyString(map['severityGroup']) ?? _toNonEmptyString(groupingMap?['severityGroup']),
    treatmentPhase: _toNonEmptyString(map['treatmentPhase']) ?? _toNonEmptyString(groupingMap?['treatmentPhase']),
  );
}

DoctorPatientGrouping decodeDoctorPatientGrouping(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorPatientGrouping(
    severityGroup: _toNonEmptyString(map['severityGroup']),
    treatmentPhase: _toNonEmptyString(map['treatmentPhase']),
  );
}

List<DoctorPatientGroupingHistoryItem> decodeDoctorPatientGroupingHistory(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          DoctorPatientGroupingHistoryItem(
            historyId: _toInt(raw['historyId']) ?? _toInt(raw['id']) ?? 0,
            severityGroup: _toNonEmptyString(raw['severityGroup']),
            treatmentPhase: _toNonEmptyString(raw['treatmentPhase']),
            createdAt: _toDateTime(raw['createdAt']),
          ),
  ];
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

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final n = value.toLowerCase().trim();
    return n == 'true' || n == '1';
  }
  return false;
}
