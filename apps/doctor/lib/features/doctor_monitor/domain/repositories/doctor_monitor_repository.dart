import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';

abstract interface class DoctorMonitorRepository {
  Future<Result<List<SideEffectSummaryItem>>> fetchSideEffectSummary({
    required int patientUserId,
    int days = 30,
  });

  Future<Result<List<WeightTrendPoint>>> fetchWeightTrend({
    required int patientUserId,
    int days = 180,
  });
}
