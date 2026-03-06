import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';

String formatMedicationDoseText(MedicationRecord record) {
  final amount = _formatAmount(record.doseAmount);
  final doseUnitLabel = _doseUnitLabel(record.doseUnit);

  if (record.doseUnit == MedicationDoseUnit.tablet) {
    final strengthAmount = _formatAmount(record.tabletStrengthAmount);
    final strengthUnitLabel = _strengthUnitLabel(record.tabletStrengthUnit);
    if (strengthAmount.isNotEmpty && strengthUnitLabel.isNotEmpty) {
      return '每次 $amount $doseUnitLabel（每片 $strengthAmount $strengthUnitLabel）';
    }
  }

  return '每次 $amount $doseUnitLabel';
}

String _formatAmount(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _doseUnitLabel(MedicationDoseUnit unit) {
  return switch (unit) {
    MedicationDoseUnit.mg => 'mg',
    MedicationDoseUnit.g => 'g',
    MedicationDoseUnit.tablet => '片',
  };
}

String _strengthUnitLabel(MedicationStrengthUnit? unit) {
  return switch (unit) {
    MedicationStrengthUnit.mg => 'mg',
    MedicationStrengthUnit.g => 'g',
    null => '',
  };
}
