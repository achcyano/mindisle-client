import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/domain/repositories/doctor_binding_repository.dart';

final class CreateDoctorBindingCodeUseCase {
  const CreateDoctorBindingCodeUseCase(this._repository);

  final DoctorBindingRepository _repository;

  Future<Result<DoctorBindingCode>> execute() => _repository.createBindingCode();
}

final class FetchDoctorBindingHistoryUseCase {
  const FetchDoctorBindingHistoryUseCase(this._repository);

  final DoctorBindingRepository _repository;

  Future<Result<DoctorBindingHistoryResult>> execute({
    int limit = 20,
    String? cursor,
    int? patientUserId,
  }) {
    return _repository.fetchBindingHistory(
      limit: limit,
      cursor: cursor,
      patientUserId: patientUserId,
    );
  }
}
