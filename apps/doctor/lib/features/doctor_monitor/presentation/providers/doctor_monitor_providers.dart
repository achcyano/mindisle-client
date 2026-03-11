import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_monitor/data/remote/doctor_monitor_api.dart';
import 'package:doctor/features/doctor_monitor/data/repositories/doctor_monitor_repository_impl.dart';
import 'package:doctor/features/doctor_monitor/domain/repositories/doctor_monitor_repository.dart';
import 'package:doctor/features/doctor_monitor/domain/usecases/doctor_monitor_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorMonitorApiProvider = Provider<DoctorMonitorApi>((ref) {
  return DoctorMonitorApi(ref.watch(appDioProvider));
});

final doctorMonitorRepositoryProvider = Provider<DoctorMonitorRepository>((
  ref,
) {
  return DoctorMonitorRepositoryImpl(ref.watch(doctorMonitorApiProvider));
});

final fetchDoctorSideEffectSummaryUseCaseProvider =
    Provider<FetchDoctorSideEffectSummaryUseCase>((ref) {
      return FetchDoctorSideEffectSummaryUseCase(
        ref.watch(doctorMonitorRepositoryProvider),
      );
    });

final fetchDoctorWeightTrendUseCaseProvider =
    Provider<FetchDoctorWeightTrendUseCase>((ref) {
      return FetchDoctorWeightTrendUseCase(
        ref.watch(doctorMonitorRepositoryProvider),
      );
    });
