import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_patient/data/remote/doctor_patient_api.dart';
import 'package:doctor/features/doctor_patient/data/repositories/doctor_patient_repository_impl.dart';
import 'package:doctor/features/doctor_patient/domain/repositories/doctor_patient_repository.dart';
import 'package:doctor/features/doctor_patient/domain/usecases/doctor_patient_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorPatientApiProvider = Provider<DoctorPatientApi>((ref) {
  return DoctorPatientApi(ref.watch(appDioProvider));
});

final doctorPatientRepositoryProvider = Provider<DoctorPatientRepository>((
  ref,
) {
  return DoctorPatientRepositoryImpl(ref.watch(doctorPatientApiProvider));
});

final fetchDoctorPatientsUseCaseProvider = Provider<FetchDoctorPatientsUseCase>(
  (ref) {
    return FetchDoctorPatientsUseCase(
      ref.watch(doctorPatientRepositoryProvider),
    );
  },
);

final updateDoctorPatientGroupingUseCaseProvider =
    Provider<UpdateDoctorPatientGroupingUseCase>((ref) {
      return UpdateDoctorPatientGroupingUseCase(
        ref.watch(doctorPatientRepositoryProvider),
      );
    });

final fetchDoctorPatientGroupingHistoryUseCaseProvider =
    Provider<FetchDoctorPatientGroupingHistoryUseCase>((ref) {
      return FetchDoctorPatientGroupingHistoryUseCase(
        ref.watch(doctorPatientRepositoryProvider),
      );
    });
