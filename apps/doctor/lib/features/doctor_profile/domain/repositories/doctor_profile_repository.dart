import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';

abstract interface class DoctorProfileRepository {
  Future<Result<DoctorProfile>> fetchProfile();

  Future<Result<DoctorThresholds>> fetchThresholds();

  Future<Result<DoctorThresholds>> updateThresholds(DoctorThresholds payload);
}
