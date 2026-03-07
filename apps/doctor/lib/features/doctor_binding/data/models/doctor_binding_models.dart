import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';

DoctorBindingCode decodeDoctorBindingCode(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  return DoctorBindingCode(
    code: (map['code'] as String?) ?? '',
    expiresAt: _toDateTime(map['expiresAt']),
    qrPayload: (map['qrPayload'] as String?) ?? '',
  );
}

DoctorBindingHistoryResult decodeDoctorBindingHistory(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];
  return DoctorBindingHistoryResult(
    items: [
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map) _decodeHistoryItem(Map<String, dynamic>.from(raw)),
    ],
    nextCursor: _toNonEmptyString(map['nextCursor']),
  );
}

DoctorBindingHistoryItem _decodeHistoryItem(Map<String, dynamic> map) {
  return DoctorBindingHistoryItem(
    bindingId: _toInt(map['bindingId']) ?? _toInt(map['id']) ?? 0,
    patientUserId: _toInt(map['patientUserId']) ?? 0,
    patientName: _toNonEmptyString(map['patientName']) ?? '',
    status: _toNonEmptyString(map['status']) ?? 'UNKNOWN',
    boundAt: _toDateTime(map['boundAt']),
    unboundAt: _toDateTime(map['unboundAt']),
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
  final t = value.trim();
  return t.isEmpty ? null : t;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
