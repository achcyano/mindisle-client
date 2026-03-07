import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';

DoctorProfile decodeDoctorProfile(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorProfile(
    doctorId: _toInt(map['doctorId']) ?? _toInt(map['id']) ?? 0,
    phone: (map['phone'] as String?) ?? '',
    fullName: (map['fullName'] as String?) ?? '',
    title: map['title'] as String?,
    hospital: map['hospital'] as String?,
  );
}

DoctorThresholds decodeDoctorThresholds(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorThresholds(
    scl90Threshold: _toInt(map['scl90Threshold']),
    phq9Threshold: _toInt(map['phq9Threshold']),
    gad7Threshold: _toInt(map['gad7Threshold']),
    psqiThreshold: _toInt(map['psqiThreshold']),
  );
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
