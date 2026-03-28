import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

abstract interface class DoctorScaleRepository {
  Future<Result<DoctorAssessmentReport>> generateAssessmentReport({
    required int patientUserId,
    int? days,
  });

  Future<Result<DoctorAssessmentReportSummary>> fetchLatestAssessmentReport({
    required int patientUserId,
  });

  Future<Result<DoctorAssessmentReportListResult>> fetchAssessmentReports({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  });

  Future<Result<DoctorAssessmentReportDetail>> fetchAssessmentReportDetail({
    required int patientUserId,
    required int reportId,
  });

  Future<Result<DoctorScaleAnswerRecordListResult>> fetchScaleAnswerRecords({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  });

  Future<Result<DoctorScaleSessionResult>> fetchSessionResult({
    required int patientUserId,
    required int sessionId,
  });
}
