import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

final class DoctorPatientState {
  const DoctorPatientState({
    this.isLoading = false,
    this.items = const <DoctorPatient>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<DoctorPatient> items;
  final String? errorMessage;

  DoctorPatientState copyWith({
    bool? isLoading,
    List<DoctorPatient>? items,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorPatientState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
