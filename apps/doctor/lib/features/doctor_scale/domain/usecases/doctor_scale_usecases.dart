import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/domain/repositories/doctor_scale_repository.dart';

final class FetchDoctorScaleTrendsUseCase {
  const FetchDoctorScaleTrendsUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<List<DoctorScaleTrendPoint>>> execute({
    required int patientUserId,
    int days = 180,
  }) {
    return _repository.fetchScaleTrends(patientUserId: patientUserId, days: days);
  }
}

final class GenerateDoctorAssessmentReportUseCase {
  const GenerateDoctorAssessmentReportUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorAssessmentReport>> execute({
    required int patientUserId,
    int? days,
  }) {
    return _repository.generateAssessmentReport(patientUserId: patientUserId, days: days);
  }
}
