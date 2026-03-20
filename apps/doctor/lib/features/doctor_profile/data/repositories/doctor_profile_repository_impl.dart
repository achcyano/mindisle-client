import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_profile/data/models/doctor_profile_models.dart';
import 'package:doctor/features/doctor_profile/data/remote/doctor_profile_api.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/domain/repositories/doctor_profile_repository.dart';

final class DoctorProfileRepositoryImpl implements DoctorProfileRepository {
  DoctorProfileRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorProfileApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<DoctorProfile>> fetchProfile() {
    return _executor.run(_api.fetchProfile, decodeDoctorProfile);
  }

  @override
  Future<Result<DoctorProfile>> updateProfile(
    DoctorProfileUpdatePayload payload,
  ) {
    return _executor.run(
      () => _api.updateProfile(payload),
      decodeDoctorProfile,
    );
  }

  @override
  Future<Result<DoctorThresholds>> fetchThresholds() {
    return _executor.run(_api.fetchThresholds, decodeDoctorThresholds);
  }

  @override
  Future<Result<DoctorThresholds>> updateThresholds(DoctorThresholds payload) {
    return _executor.run(
      () => _api.updateThresholds(payload),
      decodeDoctorThresholds,
    );
  }
}
