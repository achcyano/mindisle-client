import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/domain/repositories/doctor_scale_repository.dart';

final class GenerateDoctorAssessmentReportUseCase {
  const GenerateDoctorAssessmentReportUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorAssessmentReport>> execute({
    required int patientUserId,
    int? days,
  }) {
    return _repository.generateAssessmentReport(
      patientUserId: patientUserId,
      days: days,
    );
  }
}

final class FetchDoctorLatestAssessmentReportUseCase {
  const FetchDoctorLatestAssessmentReportUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorAssessmentReportSummary>> execute({
    required int patientUserId,
  }) {
    return _repository.fetchLatestAssessmentReport(
      patientUserId: patientUserId,
    );
  }
}

final class FetchDoctorAssessmentReportsUseCase {
  const FetchDoctorAssessmentReportsUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorAssessmentReportListResult>> execute({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchAssessmentReports(
      patientUserId: patientUserId,
      limit: limit,
      cursor: cursor,
    );
  }
}

final class FetchDoctorAssessmentReportDetailUseCase {
  const FetchDoctorAssessmentReportDetailUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorAssessmentReportDetail>> execute({
    required int patientUserId,
    required int reportId,
  }) {
    return _repository.fetchAssessmentReportDetail(
      patientUserId: patientUserId,
      reportId: reportId,
    );
  }
}

final class FetchDoctorScaleAnswerRecordsUseCase {
  const FetchDoctorScaleAnswerRecordsUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorScaleAnswerRecordListResult>> execute({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchScaleAnswerRecords(
      patientUserId: patientUserId,
      limit: limit,
      cursor: cursor,
    );
  }
}

final class FetchDoctorScaleSessionResultUseCase {
  const FetchDoctorScaleSessionResultUseCase(this._repository);

  final DoctorScaleRepository _repository;

  Future<Result<DoctorScaleSessionResult>> execute({
    required int patientUserId,
    required int sessionId,
  }) {
    return _repository.fetchSessionResult(
      patientUserId: patientUserId,
      sessionId: sessionId,
    );
  }
}
