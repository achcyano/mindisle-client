import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';

final class DoctorBindingState {
  const DoctorBindingState({
    this.isLoading = false,
    this.latestCode,
    this.history = const <DoctorBindingHistoryItem>[],
    this.errorMessage,
  });

  final bool isLoading;
  final DoctorBindingCode? latestCode;
  final List<DoctorBindingHistoryItem> history;
  final String? errorMessage;

  DoctorBindingState copyWith({
    bool? isLoading,
    Object? latestCode = _sentinel,
    List<DoctorBindingHistoryItem>? history,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorBindingState(
      isLoading: isLoading ?? this.isLoading,
      latestCode: identical(latestCode, _sentinel)
          ? this.latestCode
          : latestCode as DoctorBindingCode?,
      history: history ?? this.history,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
