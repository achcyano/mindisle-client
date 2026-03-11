import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/data/models/doctor_scale_models.dart';
import 'package:doctor/features/doctor_scale/data/remote/doctor_scale_api.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/domain/repositories/doctor_scale_repository.dart';

final class DoctorScaleRepositoryImpl implements DoctorScaleRepository {
  DoctorScaleRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorScaleApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<List<DoctorScaleTrendPoint>>> fetchScaleTrends({
    required int patientUserId,
    int days = 180,
  }) {
    return _executor.run(
      () => _api.fetchScaleTrends(patientUserId: patientUserId, days: days),
      decodeDoctorScaleTrends,
    );
  }

  @override
  Future<Result<DoctorAssessmentReport>> generateAssessmentReport({
    required int patientUserId,
    int? days,
  }) {
    return _executor.run(
      () => _api.generateAssessmentReport(
        patientUserId: patientUserId,
        days: days,
      ),
      decodeDoctorAssessmentReport,
    );
  }
}
