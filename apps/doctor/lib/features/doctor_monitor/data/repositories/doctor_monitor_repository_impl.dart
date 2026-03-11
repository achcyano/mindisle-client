import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_monitor/data/models/doctor_monitor_models.dart';
import 'package:doctor/features/doctor_monitor/data/remote/doctor_monitor_api.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_monitor/domain/repositories/doctor_monitor_repository.dart';

final class DoctorMonitorRepositoryImpl implements DoctorMonitorRepository {
  DoctorMonitorRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorMonitorApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<List<SideEffectSummaryItem>>> fetchSideEffectSummary({
    required int patientUserId,
    int days = 30,
  }) {
    return _executor.run(
      () =>
          _api.fetchSideEffectSummary(patientUserId: patientUserId, days: days),
      decodeSideEffectSummary,
    );
  }

  @override
  Future<Result<List<WeightTrendPoint>>> fetchWeightTrend({
    required int patientUserId,
    int days = 180,
  }) {
    return _executor.run(
      () => _api.fetchWeightTrend(patientUserId: patientUserId, days: days),
      decodeWeightTrend,
    );
  }
}
