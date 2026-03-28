import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_patient/data/models/doctor_patient_models.dart';
import 'package:doctor/features/doctor_patient/data/remote/doctor_patient_api.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/domain/repositories/doctor_patient_repository.dart';

final class DoctorPatientRepositoryImpl implements DoctorPatientRepository {
  DoctorPatientRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorPatientApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<DoctorPatientListResult>> fetchPatients({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchPatients(query: query, limit: limit, cursor: cursor),
      decodeDoctorPatientList,
    );
  }

  @override
  Future<Result<DoctorPatientGrouping>> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) {
    return _executor.run(
      () => _api.updateGrouping(patientUserId: patientUserId, payload: payload),
      decodeDoctorPatientGrouping,
    );
  }

  @override
  Future<Result<List<DoctorPatientGroupingHistoryItem>>> fetchGroupingHistory({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchGroupingHistory(
        patientUserId: patientUserId,
        limit: limit,
        cursor: cursor,
      ),
      decodeDoctorPatientGroupingHistory,
    );
  }
}
