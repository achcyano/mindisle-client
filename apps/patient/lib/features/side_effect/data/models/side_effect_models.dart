import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';

final class CreateSideEffectRequestDto {
  const CreateSideEffectRequestDto({
    required this.symptom,
    required this.severity,
    this.note,
    this.recordedAt,
  });

  factory CreateSideEffectRequestDto.fromDomain(CreateSideEffectPayload payload) {
    return CreateSideEffectRequestDto(
      symptom: payload.symptom,
      severity: payload.severity,
      note: payload.note,
      recordedAt: payload.recordedAt,
    );
  }

  final String symptom;
  final int severity;
  final String? note;
  final DateTime? recordedAt;

  Map<String, dynamic> toJson() {
    return {
      'symptom': symptom,
      'severity': severity,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
      if (recordedAt != null) 'recordedAt': recordedAt!.toUtc().toIso8601String(),
    };
  }
}

final class SideEffectRecordDto {
  const SideEffectRecordDto({
    required this.sideEffectId,
    required this.symptom,
    required this.severity,
    required this.note,
    required this.recordedAt,
    required this.createdAt,
  });

  factory SideEffectRecordDto.fromJson(Map<String, dynamic> json) {
    return SideEffectRecordDto(
      sideEffectId: _toInt(json['sideEffectId']) ?? _toInt(json['id']) ?? 0,
      symptom: _toNonEmptyString(json['symptom']) ?? '',
      severity: _toInt(json['severity']) ?? 0,
      note: _toNonEmptyString(json['note']),
      recordedAt: _toDateTime(json['recordedAt']),
      createdAt: _toDateTime(json['createdAt']),
    );
  }

  final int sideEffectId;
  final String symptom;
  final int severity;
  final String? note;
  final DateTime? recordedAt;
  final DateTime? createdAt;

  SideEffectRecord toDomain() {
    return SideEffectRecord(
      sideEffectId: sideEffectId,
      symptom: symptom,
      severity: severity,
      note: note,
      recordedAt: recordedAt,
      createdAt: createdAt,
    );
  }
}

final class SideEffectListResultDto {
  const SideEffectListResultDto({
    required this.items,
    required this.nextCursor,
  });

  factory SideEffectListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return SideEffectListResultDto(
      items: [
        if (rawItems is List)
          for (final raw in rawItems)
            if (raw is Map)
              SideEffectRecordDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      nextCursor: _toNonEmptyString(json['nextCursor']),
    );
  }

  final List<SideEffectRecordDto> items;
  final String? nextCursor;

  SideEffectListResult toDomain() {
    return SideEffectListResult(
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
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
