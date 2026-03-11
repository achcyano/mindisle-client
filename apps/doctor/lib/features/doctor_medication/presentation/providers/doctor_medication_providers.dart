import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_medication/data/remote/doctor_medication_api.dart';
import 'package:doctor/features/doctor_medication/data/repositories/doctor_medication_repository_impl.dart';
import 'package:doctor/features/doctor_medication/domain/repositories/doctor_medication_repository.dart';
import 'package:doctor/features/doctor_medication/domain/usecases/doctor_medication_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorMedicationApiProvider = Provider<DoctorMedicationApi>((ref) {
  return DoctorMedicationApi(ref.watch(appDioProvider));
});

final doctorMedicationRepositoryProvider = Provider<DoctorMedicationRepository>(
  (ref) {
    return DoctorMedicationRepositoryImpl(
      ref.watch(doctorMedicationApiProvider),
    );
  },
);

final fetchDoctorMedicationsUseCaseProvider =
    Provider<FetchDoctorMedicationsUseCase>((ref) {
      return FetchDoctorMedicationsUseCase(
        ref.watch(doctorMedicationRepositoryProvider),
      );
    });

final createDoctorMedicationUseCaseProvider =
    Provider<CreateDoctorMedicationUseCase>((ref) {
      return CreateDoctorMedicationUseCase(
        ref.watch(doctorMedicationRepositoryProvider),
      );
    });

final updateDoctorMedicationUseCaseProvider =
    Provider<UpdateDoctorMedicationUseCase>((ref) {
      return UpdateDoctorMedicationUseCase(
        ref.watch(doctorMedicationRepositoryProvider),
      );
    });

final deleteDoctorMedicationUseCaseProvider =
    Provider<DeleteDoctorMedicationUseCase>((ref) {
      return DeleteDoctorMedicationUseCase(
        ref.watch(doctorMedicationRepositoryProvider),
      );
    });
