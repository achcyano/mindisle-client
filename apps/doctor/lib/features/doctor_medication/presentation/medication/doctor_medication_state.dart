import 'package:models/models.dart';

final class DoctorMedicationState {
  const DoctorMedicationState({
    this.isLoading = false,
    this.items = const <MedicationRecord>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<MedicationRecord> items;
  final String? errorMessage;

  DoctorMedicationState copyWith({
    bool? isLoading,
    List<MedicationRecord>? items,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorMedicationState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

