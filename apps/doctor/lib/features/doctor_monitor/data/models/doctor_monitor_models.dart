import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';

List<SideEffectSummaryItem> decodeSideEffectSummary(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'] ?? map['summary'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          SideEffectSummaryItem(
            symptom: (raw['symptom'] as String?) ?? '',
            count: _toInt(raw['count']) ?? 0,
            averageSeverity: _toDouble(raw['averageSeverity']),
          ),
  ];
}

List<WeightTrendPoint> decodeWeightTrend(Object? rawData) {
  final map = Map<String, dynamic>.from(rawData as Map);
  final rawItems = map['items'] ?? map['points'];
  return [
    if (rawItems is List)
      for (final raw in rawItems)
        if (raw is Map)
          WeightTrendPoint(
            date: _toDateTime(raw['recordedDate']) ?? _toDateTime(raw['date']),
            weightKg: _toDouble(raw['weightKg']) ?? _toDouble(raw['weight']),
          ),
  ];
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

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
