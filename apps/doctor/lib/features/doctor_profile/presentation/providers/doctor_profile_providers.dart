import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_profile/data/remote/doctor_profile_api.dart';
import 'package:doctor/features/doctor_profile/data/repositories/doctor_profile_repository_impl.dart';
import 'package:doctor/features/doctor_profile/domain/repositories/doctor_profile_repository.dart';
import 'package:doctor/features/doctor_profile/domain/usecases/doctor_profile_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorProfileApiProvider = Provider<DoctorProfileApi>((ref) {
  return DoctorProfileApi(ref.watch(appDioProvider));
});

final doctorProfileRepositoryProvider = Provider<DoctorProfileRepository>((ref) {
  return DoctorProfileRepositoryImpl(ref.watch(doctorProfileApiProvider));
});

final fetchDoctorProfileUseCaseProvider = Provider<FetchDoctorProfileUseCase>((ref) {
  return FetchDoctorProfileUseCase(ref.watch(doctorProfileRepositoryProvider));
});

final fetchDoctorThresholdsUseCaseProvider = Provider<FetchDoctorThresholdsUseCase>((ref) {
  return FetchDoctorThresholdsUseCase(ref.watch(doctorProfileRepositoryProvider));
});

final updateDoctorThresholdsUseCaseProvider = Provider<UpdateDoctorThresholdsUseCase>((ref) {
  return UpdateDoctorThresholdsUseCase(ref.watch(doctorProfileRepositoryProvider));
});
