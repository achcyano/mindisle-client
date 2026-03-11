import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';

typedef DoctorProfileState = AsyncState<DoctorProfileData>;

final class DoctorProfileData {
  const DoctorProfileData({this.profile, this.thresholds});

  final DoctorProfile? profile;
  final DoctorThresholds? thresholds;

  DoctorProfileData copyWith({
    Object? profile = asyncStateNoChange,
    Object? thresholds = asyncStateNoChange,
  }) {
    return DoctorProfileData(
      profile: identical(profile, asyncStateNoChange)
          ? this.profile
          : profile as DoctorProfile?,
      thresholds: identical(thresholds, asyncStateNoChange)
          ? this.thresholds
          : thresholds as DoctorThresholds?,
    );
  }
}
