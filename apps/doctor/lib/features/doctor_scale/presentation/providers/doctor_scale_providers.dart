import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_scale/data/remote/doctor_scale_api.dart';
import 'package:doctor/features/doctor_scale/data/repositories/doctor_scale_repository_impl.dart';
import 'package:doctor/features/doctor_scale/domain/repositories/doctor_scale_repository.dart';
import 'package:doctor/features/doctor_scale/domain/usecases/doctor_scale_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorScaleApiProvider = Provider<DoctorScaleApi>((ref) {
  return DoctorScaleApi(ref.watch(appDioProvider));
});

final doctorScaleRepositoryProvider = Provider<DoctorScaleRepository>((ref) {
  return DoctorScaleRepositoryImpl(ref.watch(doctorScaleApiProvider));
});

final fetchDoctorScaleTrendsUseCaseProvider = Provider<FetchDoctorScaleTrendsUseCase>((ref) {
  return FetchDoctorScaleTrendsUseCase(ref.watch(doctorScaleRepositoryProvider));
});

final generateDoctorAssessmentReportUseCaseProvider =
    Provider<GenerateDoctorAssessmentReportUseCase>((ref) {
  return GenerateDoctorAssessmentReportUseCase(ref.watch(doctorScaleRepositoryProvider));
});
