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

final class FetchDoctorPatientGroupsUseCase {
  const FetchDoctorPatientGroupsUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<List<DoctorPatientGroupOption>>> execute() {
    return _repository.fetchPatientGroups();
  }
}

final class CreateDoctorPatientGroupUseCase {
  const CreateDoctorPatientGroupUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientGroupOption>> execute({
    required String severityGroup,
  }) {
    return _repository.createPatientGroup(severityGroup: severityGroup);
  }
}

final class UpdateDoctorPatientDiagnosisUseCase {
  const UpdateDoctorPatientDiagnosisUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientDiagnosisUpdateResult>> execute({
    required int patientUserId,
    required DoctorPatientDiagnosisUpdatePayload payload,
  }) {
    return _repository.updateDiagnosis(
      patientUserId: patientUserId,
      payload: payload,
    );
  }
}

final class FetchDoctorPatientProfileUseCase {
  const FetchDoctorPatientProfileUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientProfile>> execute({required int patientUserId}) {
    return _repository.fetchPatientProfile(patientUserId: patientUserId);
  }
}

final class ExportDoctorPatientsUseCase {
  const ExportDoctorPatientsUseCase(this._repository);

  final DoctorPatientRepository _repository;

  Future<Result<DoctorPatientExportFile>> execute() {
    return _repository.exportPatients();
  }
}
