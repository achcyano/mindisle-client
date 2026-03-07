import 'package:models/models.dart';

Map<String, dynamic> upsertMedicationPayloadToJson(UpsertMedicationPayload payload) {
  final doseUnitWire = medicationDoseUnitToWire(payload.doseUnit);
  return {
    'drugName': payload.drugName,
    'doseTimes': payload.doseTimes,
    'endDate': payload.endDate,
    'doseAmount': payload.doseAmount,
    'doseUnit': doseUnitWire,
    'tabletStrengthAmount': payload.doseUnit == MedicationDoseUnit.tablet
        ? payload.tabletStrengthAmount
        : null,
    'tabletStrengthUnit': payload.doseUnit == MedicationDoseUnit.tablet &&
            payload.tabletStrengthUnit != null
        ? medicationStrengthUnitToWire(payload.tabletStrengthUnit!)
        : null,
  };
}

MedicationRecord decodeMedicationRecord(Object? rawData) {
  final json = Map<String, dynamic>.from(rawData as Map);
  return MedicationRecord(
    medicationId: _toInt(json['medicationId']) ?? _toInt(json['id']) ?? 0,
    drugName: _toText(json['drugName']) ?? '',
    doseTimes: _toStringList(json['doseTimes']),
    recordedDate: _toText(json['recordedDate']) ?? '',
    endDate: _toText(json['endDate']) ?? '',
    doseAmount: _toDouble(json['doseAmount']) ?? 0,
    doseUnit: medicationDoseUnitFromWire(json['doseUnit'] as String?),
    tabletStrengthAmount: _toDouble(json['tabletStrengthAmount']),
    tabletStrengthUnit: _toStrength(json['tabletStrengthUnit']),
    isActive: _toBool(json['isActive']),
    createdAt: _toDateTime(json['createdAt']),
    updatedAt: _toDateTime(json['updatedAt']),
  );
}

MedicationListResult decodeMedicationList(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'];
  return MedicationListResult(
    items: [
      if (rawItems is List)
        for (final raw in rawItems)
          if (raw is Map) decodeMedicationRecord(raw),
    ],
    activeCount: _toInt(map['activeCount']) ?? 0,
    nextCursor: _toText(map['nextCursor']),
  );
}

MedicationStrengthUnit? _toStrength(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return medicationStrengthUnitFromWire(raw);
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
    final normalized = value.toLowerCase().trim();
    return normalized == '1' || normalized == 'true';
  }
  return false;
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _toText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

List<String> _toStringList(Object? value) {
  if (value is! List) return const <String>[];
  final out = <String>[];
  for (final item in value) {
    final txt = item.toString().trim();
    if (txt.isNotEmpty) out.add(txt);
  }
  return out;
}

