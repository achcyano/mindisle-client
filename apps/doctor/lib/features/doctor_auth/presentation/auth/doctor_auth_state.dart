import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';

final class DoctorAuthState {
  const DoctorAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSession,
  });

  final bool isLoading;
  final String? errorMessage;
  final DoctorAuthSession? lastSession;

  DoctorAuthState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? lastSession = _sentinel,
  }) {
    return DoctorAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      lastSession: identical(lastSession, _sentinel)
          ? this.lastSession
          : lastSession as DoctorAuthSession?,
    );
  }
}

const Object _sentinel = Object();
