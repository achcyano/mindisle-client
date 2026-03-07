import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';

final class DoctorProfileState {
  const DoctorProfileState({
    this.isLoading = false,
    this.profile,
    this.thresholds,
    this.errorMessage,
  });

  final bool isLoading;
  final DoctorProfile? profile;
  final DoctorThresholds? thresholds;
  final String? errorMessage;

  DoctorProfileState copyWith({
    bool? isLoading,
    Object? profile = _sentinel,
    Object? thresholds = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: identical(profile, _sentinel) ? this.profile : profile as DoctorProfile?,
      thresholds: identical(thresholds, _sentinel)
          ? this.thresholds
          : thresholds as DoctorThresholds?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
