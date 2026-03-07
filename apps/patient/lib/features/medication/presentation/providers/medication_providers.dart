import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/features/medication/data/remote/medication_api.dart';
import 'package:patient/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:patient/features/medication/domain/repositories/medication_repository.dart';
import 'package:patient/features/medication/domain/usecases/medication_usecases.dart';

final medicationApiProvider = Provider<MedicationApi>((ref) {
  return MedicationApi(ref.watch(appDioProvider));
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(medicationApiProvider));
});

final fetchMedicationsUseCaseProvider = Provider<FetchMedicationsUseCase>((ref) {
  return FetchMedicationsUseCase(ref.watch(medicationRepositoryProvider));
});

final createMedicationUseCaseProvider = Provider<CreateMedicationUseCase>((ref) {
  return CreateMedicationUseCase(ref.watch(medicationRepositoryProvider));
});

final updateMedicationUseCaseProvider = Provider<UpdateMedicationUseCase>((ref) {
  return UpdateMedicationUseCase(ref.watch(medicationRepositoryProvider));
});

final deleteMedicationUseCaseProvider = Provider<DeleteMedicationUseCase>((ref) {
  return DeleteMedicationUseCase(ref.watch(medicationRepositoryProvider));
});
