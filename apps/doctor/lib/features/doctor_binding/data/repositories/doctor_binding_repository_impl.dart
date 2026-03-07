import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_binding/data/models/doctor_binding_models.dart';
import 'package:doctor/features/doctor_binding/data/remote/doctor_binding_api.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/domain/repositories/doctor_binding_repository.dart';

final class DoctorBindingRepositoryImpl implements DoctorBindingRepository {
  DoctorBindingRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorBindingApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<DoctorBindingCode>> createBindingCode() {
    return _executor.run(_api.createBindingCode, decodeDoctorBindingCode);
  }

  @override
  Future<Result<DoctorBindingHistoryResult>> fetchBindingHistory({
    int limit = 20,
    String? cursor,
    int? patientUserId,
  }) {
    return _executor.run(
      () => _api.fetchBindingHistory(
        limit: limit,
        cursor: cursor,
        patientUserId: patientUserId,
      ),
      decodeDoctorBindingHistory,
    );
  }
}
