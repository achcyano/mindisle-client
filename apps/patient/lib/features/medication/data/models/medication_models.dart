import 'package:patient/features/medication/domain/entities/medication_entities.dart';

final class UpsertMedicationRequestDto {
  const UpsertMedicationRequestDto({
    required this.drugName,
    required this.doseTimes,
    required this.endDate,
    required this.doseAmount,
    required this.doseUnit,
    required this.tabletStrengthAmount,
    required this.tabletStrengthUnit,
  });

  factory UpsertMedicationRequestDto.fromDomain(UpsertMedicationPayload payload) {
    return UpsertMedicationRequestDto(
      drugName: payload.drugName,
      doseTimes: payload.doseTimes,
      endDate: payload.endDate,
      doseAmount: payload.doseAmount,
      doseUnit: payload.doseUnit,
      tabletStrengthAmount: payload.tabletStrengthAmount,
      tabletStrengthUnit: payload.tabletStrengthUnit,
    );
  }

  final String drugName;
  final List<String> doseTimes;
  final String endDate;
  final double doseAmount;
  final MedicationDoseUnit doseUnit;
  final double? tabletStrengthAmount;
  final MedicationStrengthUnit? tabletStrengthUnit;

  Map<String, dynamic> toJson() {
    final doseUnitWire = medicationDoseUnitToWire(doseUnit);
    return {
      'drugName': drugName,
      'doseTimes': doseTimes,
      'endDate': endDate,
      'doseAmount': doseAmount,
      'doseUnit': doseUnitWire,
      'tabletStrengthAmount': doseUnit == MedicationDoseUnit.tablet
          ? tabletStrengthAmount
          : null,
      'tabletStrengthUnit': doseUnit == MedicationDoseUnit.tablet &&
              tabletStrengthUnit != null
          ? medicationStrengthUnitToWire(tabletStrengthUnit!)
          : null,
    };
  }
}

final class MedicationRecordDto {
  const MedicationRecordDto({
    required this.medicationId,
    required this.drugName,
    required this.doseTimes,
    required this.recordedDate,
    required this.endDate,
    required this.doseAmount,
    required this.doseUnit,
    required this.tabletStrengthAmount,
    required this.tabletStrengthUnit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationRecordDto.fromJson(Map<String, dynamic> json) {
    return MedicationRecordDto(
      medicationId: _toInt(json['medicationId']) ?? _toInt(json['id']) ?? 0,
      drugName: _toNonEmptyString(json['drugName']) ?? '',
      doseTimes: _toStringList(json['doseTimes']),
      recordedDate: _toNonEmptyString(json['recordedDate']) ?? '',
      endDate: _toNonEmptyString(json['endDate']) ?? '',
      doseAmount: _toDouble(json['doseAmount']) ?? 0,
      doseUnit: medicationDoseUnitFromWire(json['doseUnit'] as String?),
      tabletStrengthAmount: _toDouble(json['tabletStrengthAmount']),
      tabletStrengthUnit: _toStrengthOrNull(json['tabletStrengthUnit']),
      isActive: _toBool(json['isActive']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  final int medicationId;
  final String drugName;
  final List<String> doseTimes;
  final String recordedDate;
  final String endDate;
  final double doseAmount;
  final MedicationDoseUnit doseUnit;
  final double? tabletStrengthAmount;
  final MedicationStrengthUnit? tabletStrengthUnit;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicationRecord toDomain() {
    return MedicationRecord(
      medicationId: medicationId,
      drugName: drugName,
      doseTimes: doseTimes,
      recordedDate: recordedDate,
      endDate: endDate,
      doseAmount: doseAmount,
      doseUnit: doseUnit,
      tabletStrengthAmount: tabletStrengthAmount,
      tabletStrengthUnit: tabletStrengthUnit,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final class MedicationListResultDto {
  const MedicationListResultDto({
    required this.items,
    required this.activeCount,
    required this.nextCursor,
  });

  factory MedicationListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MedicationListResultDto(
      items: [
        if (rawItems is List)
          for (final raw in rawItems)
            if (raw is Map)
              MedicationRecordDto.fromJson(Map<String, dynamic>.from(raw)),
      ],
      activeCount: _toInt(json['activeCount']) ?? 0,
      nextCursor: _toNullableString(json['nextCursor']),
    );
  }

  final List<MedicationRecordDto> items;
  final int activeCount;
  final String? nextCursor;

  MedicationListResult toDomain() {
    return MedicationListResult(
      items: items.map((it) => it.toDomain()).toList(growable: false),
      activeCount: activeCount,
      nextCursor: nextCursor,
    );
  }
}

MedicationStrengthUnit? _toStrengthOrNull(Object? value) {
  if (value == null) return null;
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;
  return medicationStrengthUnitFromWire(raw);
}

String? _toNullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String? _toNonEmptyString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
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
    final raw = value.toLowerCase().trim();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
  return false;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

List<String> _toStringList(Object? value) {
  if (value is! List) return const <String>[];
  final result = <String>[];
  for (final item in value) {
    final text = item.toString().trim();
    if (text.isEmpty) continue;
    result.add(text);
  }
  return result;
}
