import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_monitor/domain/repositories/doctor_monitor_repository.dart';

final class FetchDoctorSideEffectSummaryUseCase {
  const FetchDoctorSideEffectSummaryUseCase(this._repository);

  final DoctorMonitorRepository _repository;

  Future<Result<List<SideEffectSummaryItem>>> execute({
    required int patientUserId,
    int days = 30,
  }) {
    return _repository.fetchSideEffectSummary(
      patientUserId: patientUserId,
      days: days,
    );
  }
}

final class FetchDoctorWeightTrendUseCase {
  const FetchDoctorWeightTrendUseCase(this._repository);

  final DoctorMonitorRepository _repository;

  Future<Result<List<WeightTrendPoint>>> execute({
    required int patientUserId,
    int days = 180,
  }) {
    return _repository.fetchWeightTrend(
      patientUserId: patientUserId,
      days: days,
    );
  }
}
