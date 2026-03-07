import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

abstract interface class DoctorScaleRepository {
  Future<Result<List<DoctorScaleTrendPoint>>> fetchScaleTrends({
    required int patientUserId,
    int days = 180,
  });

  Future<Result<DoctorAssessmentReport>> generateAssessmentReport({
    required int patientUserId,
    int? days,
  });
}
