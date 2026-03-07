import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_binding/data/remote/doctor_binding_api.dart';
import 'package:doctor/features/doctor_binding/data/repositories/doctor_binding_repository_impl.dart';
import 'package:doctor/features/doctor_binding/domain/repositories/doctor_binding_repository.dart';
import 'package:doctor/features/doctor_binding/domain/usecases/doctor_binding_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorBindingApiProvider = Provider<DoctorBindingApi>((ref) {
  return DoctorBindingApi(ref.watch(appDioProvider));
});

final doctorBindingRepositoryProvider = Provider<DoctorBindingRepository>((ref) {
  return DoctorBindingRepositoryImpl(ref.watch(doctorBindingApiProvider));
});

final createDoctorBindingCodeUseCaseProvider = Provider<CreateDoctorBindingCodeUseCase>((ref) {
  return CreateDoctorBindingCodeUseCase(ref.watch(doctorBindingRepositoryProvider));
});

final fetchDoctorBindingHistoryUseCaseProvider = Provider<FetchDoctorBindingHistoryUseCase>((ref) {
  return FetchDoctorBindingHistoryUseCase(ref.watch(doctorBindingRepositoryProvider));
});
