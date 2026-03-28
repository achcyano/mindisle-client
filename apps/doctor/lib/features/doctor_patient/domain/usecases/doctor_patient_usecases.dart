import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/domain/repositories/doctor_patient_repository.dart';

final class FetchDoctorPatientsUseCase {
  const FetchDoctorPatientsUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientListResult>> execute({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchPatients(
      query: query,
      limit: limit,
      cursor: cursor,
    );
  }
}

final class UpdateDoctorPatientGroupingUseCase {
  const UpdateDoctorPatientGroupingUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientGrouping>> execute({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) {
    return _repository.updateGrouping(
      patientUserId: patientUserId,
      payload: payload,
    );
  }
}

final class FetchDoctorPatientGroupingHistoryUseCase {
  const FetchDoctorPatientGroupingHistoryUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<List<DoctorPatientGroupingHistoryItem>>> execute({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchGroupingHistory(
      patientUserId: patientUserId,
      limit: limit,
      cursor: cursor,
    );
  }
}
