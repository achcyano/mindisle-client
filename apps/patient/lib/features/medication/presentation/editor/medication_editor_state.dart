import 'package:patient/features/medication/domain/entities/medication_entities.dart';

final class MedicationEditorState {
  const MedicationEditorState({
    required this.medicationId,
    required this.recordedDate,
    required this.drugName,
    required this.doseTimes,
    required this.endDate,
    required this.doseAmount,
    required this.doseUnit,
    required this.tabletStrengthAmount,
    required this.tabletStrengthUnit,
    required this.isSubmitting,
    required this.errorMessage,
  });

  factory MedicationEditorState.initial(MedicationRecord? initial) {
    if (initial == null) {
      return const MedicationEditorState(
        medicationId: null,
        recordedDate: '',
        drugName: '',
        doseTimes: <String>[],
        endDate: '',
        doseAmount: '',
        doseUnit: MedicationDoseUnit.tablet,
        tabletStrengthAmount: '',
        tabletStrengthUnit: MedicationStrengthUnit.mg,
        isSubmitting: false,
        errorMessage: null,
      );
    }

    return MedicationEditorState(
      medicationId: initial.medicationId,
      recordedDate: initial.recordedDate,
      drugName: initial.drugName,
      doseTimes: initial.doseTimes,
      endDate: initial.endDate,
      doseAmount: _formatDouble(initial.doseAmount),
      doseUnit: initial.doseUnit,
      tabletStrengthAmount: _formatDouble(initial.tabletStrengthAmount),
      tabletStrengthUnit: initial.tabletStrengthUnit ?? MedicationStrengthUnit.mg,
      isSubmitting: false,
      errorMessage: null,
    );
  }

  final int? medicationId;
  final String recordedDate;
  final String drugName;
  final List<String> doseTimes;
  final String endDate;
  final String doseAmount;
  final MedicationDoseUnit doseUnit;
  final String tabletStrengthAmount;
  final MedicationStrengthUnit tabletStrengthUnit;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isEditing => medicationId != null && medicationId! > 0;

  bool get requiresTabletStrength => doseUnit == MedicationDoseUnit.tablet;

  MedicationEditorState copyWith({
    Object? medicationId = _sentinel,
    String? recordedDate,
    String? drugName,
    List<String>? doseTimes,
    String? endDate,
    String? doseAmount,
    MedicationDoseUnit? doseUnit,
    String? tabletStrengthAmount,
    MedicationStrengthUnit? tabletStrengthUnit,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
  }) {
    return MedicationEditorState(
      medicationId: identical(medicationId, _sentinel)
          ? this.medicationId
          : medicationId as int?,
      recordedDate: recordedDate ?? this.recordedDate,
      drugName: drugName ?? this.drugName,
      doseTimes: doseTimes ?? this.doseTimes,
      endDate: endDate ?? this.endDate,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      tabletStrengthAmount: tabletStrengthAmount ?? this.tabletStrengthAmount,
      tabletStrengthUnit: tabletStrengthUnit ?? this.tabletStrengthUnit,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

String _formatDouble(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
