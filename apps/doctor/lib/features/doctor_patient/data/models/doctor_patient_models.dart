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
  final groupingMap = grouping is Map
      ? Map<String, dynamic>.from(grouping)
      : null;
  return DoctorPatient(
    patientUserId: _toInt(map['patientUserId']) ?? _toInt(map['userId']) ?? 0,
    fullName: _toNonEmptyString(map['fullName']) ?? '',
    phone: _toNonEmptyString(map['phone']) ?? '',
    isAbnormal: _toBool(map['isAbnormal']),
    severityGroup:
        _toNonEmptyString(map['severityGroup']) ??
        _toNonEmptyString(groupingMap?['severityGroup']),
    gender:
        DoctorPatientGender.fromApiValue(map['gender']) ??
        DoctorPatientGender.fromApiValue(groupingMap?['gender']),
    birthDate: _toDateTime(map['birthDate']),
    age: _toInt(map['age']),
    latestScl90Score: _toDouble(map['latestScl90Score']),
    latestAssessmentAt: _toDateTime(map['latestAssessmentAt']),
    diagnosis: _toNonEmptyString(map['diagnosis']),
  );
}

DoctorPatientGrouping decodeDoctorPatientGrouping(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorPatientGrouping(
    severityGroup: _toNonEmptyString(map['severityGroup']),
  );
}

List<DoctorPatientGroupingHistoryItem> decodeDoctorPatientGroupingHistory(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          DoctorPatientGroupingHistoryItem(
            historyId: _toInt(raw['historyId']) ?? _toInt(raw['id']) ?? 0,
            severityGroup: _toNonEmptyString(raw['severityGroup']),
            changedAt:
                _toDateTime(raw['changedAt']) ?? _toDateTime(raw['createdAt']),
            operatorDoctorId: _toInt(raw['operatorDoctorId']),
            operatorDoctorName: _toNonEmptyString(raw['operatorDoctorName']),
          ),
  ];
}

List<DoctorPatientGroupOption> decodeDoctorPatientGroupOptions(
  Object? rawData,
) {
  if (rawData is List) {
    return [
      for (final raw in rawData)
        if (raw is Map)
          if (_decodeGroupOption(Map<String, dynamic>.from(raw))
              case final option when option.severityGroup.isNotEmpty)
            option,
    ];
  }

  final map = rawData is Map<String, dynamic>
      ? rawData
      : rawData is Map
      ? Map<String, dynamic>.from(rawData)
      : const <String, dynamic>{};
  final rawItems = map['items'] ?? map['groups'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          if (_decodeGroupOption(Map<String, dynamic>.from(raw))
              case final option when option.severityGroup.isNotEmpty)
            option,
  ];
}

DoctorPatientGroupOption decodeDoctorPatientGroupOption(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return _decodeGroupOption(map);
}

DoctorPatientDiagnosisUpdateResult decodeDoctorPatientDiagnosisUpdateResult(
  Object? rawData,
) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorPatientDiagnosisUpdateResult(
    patientUserId: _toInt(map['patientUserId']) ?? _toInt(map['userId']) ?? 0,
    diagnosis: _toNonEmptyString(map['diagnosis']),
    updatedAt: _toDateTime(map['updatedAt']) ?? _toDateTime(map['changedAt']),
  );
}

DoctorPatientProfile decodeDoctorPatientProfile(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorPatientProfile(
    patientUserId: _toInt(map['patientUserId']) ?? _toInt(map['userId']),
    phone: _toNonEmptyString(map['phone']),
    fullName: _toNonEmptyString(map['fullName']),
    gender: DoctorPatientGender.fromApiValue(map['gender']),
    birthDate: _toDateTime(map['birthDate']),
    heightCm: _toDouble(map['heightCm']),
    weightKg: _toDouble(map['weightKg']),
    waistCm: _toDouble(map['waistCm']),
    usesTcm: _toBoolOrNull(map['usesTcm']),
    diseaseHistory: _toStringList(map['diseaseHistory']),
  );
}

DoctorPatientGroupOption _decodeGroupOption(Map<String, dynamic> map) {
  return DoctorPatientGroupOption(
    severityGroup: _toNonEmptyString(map['severityGroup']) ?? '',
    patientCount:
        _toInt(map['patientCount']) ?? _toInt(map['boundPatientCount']) ?? 0,
  );
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
    final n = value.toLowerCase().trim();
    return n == 'true' || n == '1';
  }
  return false;
}

bool? _toBoolOrNull(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

List<String> _toStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
