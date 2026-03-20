import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/domain/repositories/doctor_profile_repository.dart';

final class FetchDoctorProfileUseCase {
  const FetchDoctorProfileUseCase(this._repository);

  final DoctorProfileRepository _repository;

  Future<Result<DoctorProfile>> execute() => _repository.fetchProfile();
}

final class UpdateDoctorProfileUseCase {
  const UpdateDoctorProfileUseCase(this._repository);

  final DoctorProfileRepository _repository;

  Future<Result<DoctorProfile>> execute(DoctorProfileUpdatePayload payload) {
    return _repository.updateProfile(payload);
  }
}

final class FetchDoctorThresholdsUseCase {
  const FetchDoctorThresholdsUseCase(this._repository);

  final DoctorProfileRepository _repository;

  Future<Result<DoctorThresholds>> execute() => _repository.fetchThresholds();
}

final class UpdateDoctorThresholdsUseCase {
  const UpdateDoctorThresholdsUseCase(this._repository);

  final DoctorProfileRepository _repository;

  Future<Result<DoctorThresholds>> execute(DoctorThresholds payload) {
    return _repository.updateThresholds(payload);
  }
}
