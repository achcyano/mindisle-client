import 'package:patient/features/event/domain/entities/event_entities.dart';

enum PatientDoctorBindingMode { manual, scan }

const Object _bindingStateNoChange = Object();

final class PatientDoctorBindingState {
  const PatientDoctorBindingState({
    this.initialized = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isUnbinding = false,
    this.mode = PatientDoctorBindingMode.manual,
    this.inputCode = '',
    this.status,
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isSubmitting;
  final bool isUnbinding;
  final PatientDoctorBindingMode mode;
  final String inputCode;
  final DoctorBindingStatus? status;
  final String? errorMessage;

  bool get isBound => status?.isBound == true;

  bool get isBusy => isLoading || isSubmitting || isUnbinding;

  bool get canSubmitInput => !isBusy && inputCode.length == 5;

  PatientDoctorBindingState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isSubmitting,
    bool? isUnbinding,
    PatientDoctorBindingMode? mode,
    String? inputCode,
    Object? status = _bindingStateNoChange,
    Object? errorMessage = _bindingStateNoChange,
  }) {
    return PatientDoctorBindingState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUnbinding: isUnbinding ?? this.isUnbinding,
      mode: mode ?? this.mode,
      inputCode: inputCode ?? this.inputCode,
      status: identical(status, _bindingStateNoChange)
          ? this.status
          : status as DoctorBindingStatus?,
      errorMessage: identical(errorMessage, _bindingStateNoChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
