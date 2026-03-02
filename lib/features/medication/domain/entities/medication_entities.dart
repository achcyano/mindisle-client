import 'package:flutter/foundation.dart';

enum MedicationDoseUnit {
  mg,
  g,
  tablet,
}

enum MedicationStrengthUnit {
  mg,
  g,
}

String medicationDoseUnitToWire(MedicationDoseUnit unit) {
  return switch (unit) {
    MedicationDoseUnit.mg => 'MG',
    MedicationDoseUnit.g => 'G',
    MedicationDoseUnit.tablet => 'TABLET',
  };
}

MedicationDoseUnit medicationDoseUnitFromWire(String? raw) {
  return switch ((raw ?? '').toUpperCase()) {
    'MG' => MedicationDoseUnit.mg,
    'G' => MedicationDoseUnit.g,
    'TABLET' => MedicationDoseUnit.tablet,
    _ => MedicationDoseUnit.mg,
  };
}

String medicationStrengthUnitToWire(MedicationStrengthUnit unit) {
  return switch (unit) {
    MedicationStrengthUnit.mg => 'MG',
    MedicationStrengthUnit.g => 'G',
  };
}

MedicationStrengthUnit medicationStrengthUnitFromWire(String? raw) {
  return switch ((raw ?? '').toUpperCase()) {
    'MG' => MedicationStrengthUnit.mg,
    'G' => MedicationStrengthUnit.g,
    _ => MedicationStrengthUnit.mg,
  };
}

@immutable
final class MedicationRecord {
  const MedicationRecord({
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
}

@immutable
final class MedicationListResult {
  const MedicationListResult({
    required this.items,
    required this.activeCount,
    required this.nextCursor,
  });

  final List<MedicationRecord> items;
  final int activeCount;
  final String? nextCursor;
}

@immutable
final class UpsertMedicationPayload {
  const UpsertMedicationPayload({
    required this.drugName,
    required this.doseTimes,
    required this.endDate,
    required this.doseAmount,
    required this.doseUnit,
    required this.tabletStrengthAmount,
    required this.tabletStrengthUnit,
  });

  final String drugName;
  final List<String> doseTimes;
  final String endDate;
  final double doseAmount;
  final MedicationDoseUnit doseUnit;
  final double? tabletStrengthAmount;
  final MedicationStrengthUnit? tabletStrengthUnit;
}
