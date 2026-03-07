import 'package:patient/features/event/domain/entities/event_entities.dart';

UserEventType userEventTypeFromWire({
  required String? eventType,
  required String? eventName,
}) {
  final normalizedType = (eventType ?? '').trim().toUpperCase();
  if (normalizedType.isNotEmpty) {
    return switch (normalizedType) {
      'OPEN_SCALE' => UserEventType.openScale,
      'CONTINUE_SCALE_SESSION' => UserEventType.continueScaleSession,
      'BIND_DOCTOR' => UserEventType.bindDoctor,
      'IMPORT_MEDICATION_PLAN' => UserEventType.importMedicationPlan,
      'UPDATE_BASIC_PROFILE' => UserEventType.updateBasicProfile,
      _ => UserEventType.unknown,
    };
  }

  final normalizedName = (eventName ?? '').trim().toUpperCase();
  return switch (normalizedName) {
    'SCALE_REDO_DUE' => UserEventType.openScale,
    'SCALE_SESSION_IN_PROGRESS' => UserEventType.continueScaleSession,
    'DOCTOR_BIND_REQUIRED' => UserEventType.bindDoctor,
    'MEDICATION_PLAN_EMPTY' => UserEventType.importMedicationPlan,
    'PROFILE_UPDATE_MONTHLY' => UserEventType.updateBasicProfile,
    _ => UserEventType.unknown,
  };
}

final class UserEventItemDto {
  const UserEventItemDto({
    required this.eventName,
    required this.eventType,
    required this.dueAt,
    required this.persistent,
    required this.payload,
    this.scaleId,
    this.scaleCode,
    this.scaleName,
    this.intervalDays,
    this.sessionId,
    this.progress,
    this.activeMedicationCount,
    this.anchor,
  });

  factory UserEventItemDto.fromJson(Map<String, dynamic> json) {
    final eventName = _toNonEmptyString(json['eventName']) ?? '';
    final eventTypeRaw = _toNonEmptyString(json['eventType']);
    final eventType = userEventTypeFromWire(
      eventType: eventTypeRaw,
      eventName: eventName,
    );

    final rawPayload = json['payload'];
    final payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : const <String, dynamic>{};

    return UserEventItemDto(
      eventName: eventName,
      eventType: eventType,
      dueAt: _toDateTime(json['dueAt']),
      persistent: _toBool(json['persistent'], fallback: true),
      payload: payload,
      scaleId: _toInt(payload['scaleId']),
      scaleCode: _toNonEmptyString(payload['scaleCode']),
      scaleName: _toNonEmptyString(payload['scaleName']),
      intervalDays: _toInt(payload['intervalDays']),
      sessionId: _toInt(payload['sessionId']),
      progress: _toInt(payload['progress']),
      activeMedicationCount: _toInt(payload['activeMedicationCount']),
      anchor: _toNonEmptyString(payload['anchor']),
    );
  }

  final String eventName;
  final UserEventType eventType;
  final DateTime? dueAt;
  final bool persistent;
  final Map<String, dynamic> payload;

  final int? scaleId;
  final String? scaleCode;
  final String? scaleName;
  final int? intervalDays;
  final int? sessionId;
  final int? progress;
  final int? activeMedicationCount;
  final String? anchor;

  UserEventItem toDomain() {
    return UserEventItem(
      eventName: eventName,
      eventType: eventType,
      dueAt: dueAt,
      persistent: persistent,
      rawPayload: payload,
      scaleId: scaleId,
      scaleCode: scaleCode,
      scaleName: scaleName,
      intervalDays: intervalDays,
      sessionId: sessionId,
      progress: progress,
      activeMedicationCount: activeMedicationCount,
      anchor: anchor,
    );
  }
}

final class UserEventListDto {
  const UserEventListDto({
    required this.generatedAt,
    required this.items,
  });

  factory UserEventListDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return UserEventListDto(
      generatedAt: _toDateTime(json['generatedAt']),
      items: <UserEventItemDto>[
        if (rawItems is List)
          for (final raw in rawItems)
            if (raw is Map)
              UserEventItemDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
    );
  }

  final DateTime? generatedAt;
  final List<UserEventItemDto> items;

  UserEventList toDomain() {
    return UserEventList(
      generatedAt: generatedAt,
      items: items.map((it) => it.toDomain()).toList(growable: false),
    );
  }
}

final class DoctorBindingStatusDto {
  const DoctorBindingStatusDto({
    required this.isBound,
    required this.boundAt,
    required this.unboundAt,
    required this.updatedAt,
    this.currentDoctorId,
    this.currentDoctorName,
  });

  factory DoctorBindingStatusDto.fromJson(Map<String, dynamic> json) {
    final rawDoctor = json['doctor'];
    final doctorMap = rawDoctor is Map ? Map<String, dynamic>.from(rawDoctor) : null;

    return DoctorBindingStatusDto(
      isBound: _toBool(json['isBound'], fallback: false),
      boundAt: _toDateTime(json['boundAt']),
      unboundAt: _toDateTime(json['unboundAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      currentDoctorId: _toInt(json['doctorId']) ?? _toInt(doctorMap?['doctorId']) ?? _toInt(doctorMap?['id']),
      currentDoctorName: _toNonEmptyString(json['doctorName']) ?? _toNonEmptyString(doctorMap?['fullName']) ?? _toNonEmptyString(doctorMap?['name']),
    );
  }

  final bool isBound;
  final DateTime? boundAt;
  final DateTime? unboundAt;
  final DateTime? updatedAt;
  final int? currentDoctorId;
  final String? currentDoctorName;

  DoctorBindingStatus toDomain() {
    return DoctorBindingStatus(
      isBound: isBound,
      boundAt: boundAt,
      unboundAt: unboundAt,
      updatedAt: updatedAt,
      currentDoctorId: currentDoctorId,
      currentDoctorName: currentDoctorName,
    );
  }
}

final class DoctorBindingHistoryItemDto {
  const DoctorBindingHistoryItemDto({
    required this.recordId,
    required this.status,
    required this.boundAt,
    required this.unboundAt,
    this.doctorId,
    this.doctorName,
  });

  factory DoctorBindingHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final rawDoctor = json['doctor'];
    final doctorMap = rawDoctor is Map ? Map<String, dynamic>.from(rawDoctor) : null;

    return DoctorBindingHistoryItemDto(
      recordId: _toInt(json['bindingId']) ?? _toInt(json['id']) ?? 0,
      status: _toNonEmptyString(json['status']) ?? 'UNKNOWN',
      boundAt: _toDateTime(json['boundAt']),
      unboundAt: _toDateTime(json['unboundAt']),
      doctorId: _toInt(json['doctorId']) ?? _toInt(doctorMap?['doctorId']) ?? _toInt(doctorMap?['id']),
      doctorName: _toNonEmptyString(json['doctorName']) ?? _toNonEmptyString(doctorMap?['fullName']) ?? _toNonEmptyString(doctorMap?['name']),
    );
  }

  final int recordId;
  final String status;
  final DateTime? boundAt;
  final DateTime? unboundAt;
  final int? doctorId;
  final String? doctorName;

  DoctorBindingHistoryItem toDomain() {
    return DoctorBindingHistoryItem(
      recordId: recordId,
      status: status,
      boundAt: boundAt,
      unboundAt: unboundAt,
      doctorId: doctorId,
      doctorName: doctorName,
    );
  }
}

final class DoctorBindingHistoryResultDto {
  const DoctorBindingHistoryResultDto({
    required this.items,
    required this.nextCursor,
  });

  factory DoctorBindingHistoryResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return DoctorBindingHistoryResultDto(
      items: <DoctorBindingHistoryItemDto>[
        if (rawItems is List)
          for (final raw in rawItems)
            if (raw is Map)
              DoctorBindingHistoryItemDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      nextCursor: _toNonEmptyString(json['nextCursor']),
    );
  }

  final List<DoctorBindingHistoryItemDto> items;
  final String? nextCursor;

  DoctorBindingHistoryResult toDomain() {
    return DoctorBindingHistoryResult(
      items: items.map((it) => it.toDomain()).toList(growable: false),
      nextCursor: nextCursor,
    );
  }
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _toNonEmptyString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String) return null;
  if (value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

bool _toBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}
