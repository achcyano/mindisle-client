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

  @override
  Future<Result<DoctorAssessmentReportSummary>> fetchLatestAssessmentReport({
    required int patientUserId,
  }) {
    return _executor.run(
      () => _api.fetchLatestAssessmentReport(patientUserId: patientUserId),
      decodeDoctorLatestAssessmentReport,
    );
  }

  @override
  Future<Result<DoctorAssessmentReportListResult>> fetchAssessmentReports({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchAssessmentReports(
        patientUserId: patientUserId,
        limit: limit,
        cursor: cursor,
      ),
      decodeDoctorAssessmentReports,
    );
  }

  @override
  Future<Result<DoctorAssessmentReportDetail>> fetchAssessmentReportDetail({
    required int patientUserId,
    required int reportId,
  }) {
    return _executor.run(
      () => _api.fetchAssessmentReportDetail(
        patientUserId: patientUserId,
        reportId: reportId,
      ),
      decodeDoctorAssessmentReportDetail,
    );
  }

  @override
  Future<Result<DoctorScaleAnswerRecordListResult>> fetchScaleAnswerRecords({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchScaleAnswerRecords(
        patientUserId: patientUserId,
        limit: limit,
        cursor: cursor,
      ),
      decodeDoctorScaleAnswerRecords,
    );
  }

  @override
  Future<Result<DoctorScaleSessionResult>> fetchSessionResult({
    required int patientUserId,
    required int sessionId,
  }) {
    return _executor.run(
      () => _api.fetchScaleSessionResult(
        patientUserId: patientUserId,
        sessionId: sessionId,
      ),
      decodeDoctorScaleSessionResult,
    );
  }
}
