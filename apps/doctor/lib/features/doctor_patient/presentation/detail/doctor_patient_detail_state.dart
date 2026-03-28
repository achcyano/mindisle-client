import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';

typedef DoctorPatientDetailState = AsyncState<DoctorPatientDetailData>;

final class DoctorPatientDetailData {
  const DoctorPatientDetailData({
    required this.patient,
    this.patientProfile,
    this.weightTrend = const <WeightTrendPoint>[],
    this.isBasicLoading = false,
    this.basicErrorMessage,
    this.historyRecords = const <DoctorScaleAnswerRecord>[],
    this.historyNextCursor,
    this.isHistoryLoading = false,
    this.isLoadingMoreHistory = false,
    this.historyErrorMessage,
    this.latestReport,
    this.reports = const <DoctorAssessmentReportSummary>[],
    this.reportNextCursor,
    this.isReportLoading = false,
    this.isLoadingMoreReports = false,
    this.isGeneratingReport = false,
    this.reportErrorMessage,
    this.reportDetailCache = const <int, DoctorAssessmentReportDetail>{},
    this.loadingReportDetailIds = const <int>{},
    this.reportDetailErrors = const <int, String>{},
    this.selectedReportDetail,
  });

  final DoctorPatient patient;
  final DoctorPatientProfile? patientProfile;
  final List<WeightTrendPoint> weightTrend;
  final bool isBasicLoading;
  final String? basicErrorMessage;
  final List<DoctorScaleAnswerRecord> historyRecords;
  final String? historyNextCursor;
  final bool isHistoryLoading;
  final bool isLoadingMoreHistory;
  final String? historyErrorMessage;
  final DoctorAssessmentReportSummary? latestReport;
  final List<DoctorAssessmentReportSummary> reports;
  final String? reportNextCursor;
  final bool isReportLoading;
  final bool isLoadingMoreReports;
  final bool isGeneratingReport;
  final String? reportErrorMessage;
  final Map<int, DoctorAssessmentReportDetail> reportDetailCache;
  final Set<int> loadingReportDetailIds;
  final Map<int, String> reportDetailErrors;
  final DoctorAssessmentReportDetail? selectedReportDetail;

  bool get hasMoreHistory =>
      historyNextCursor != null && historyNextCursor!.isNotEmpty;
  bool get hasMoreReports =>
      reportNextCursor != null && reportNextCursor!.isNotEmpty;

  DoctorPatientDetailData copyWith({
    DoctorPatient? patient,
    Object? patientProfile = asyncStateNoChange,
    List<WeightTrendPoint>? weightTrend,
    bool? isBasicLoading,
    Object? basicErrorMessage = asyncStateNoChange,
    List<DoctorScaleAnswerRecord>? historyRecords,
    Object? historyNextCursor = asyncStateNoChange,
    bool? isHistoryLoading,
    bool? isLoadingMoreHistory,
    Object? historyErrorMessage = asyncStateNoChange,
    Object? latestReport = asyncStateNoChange,
    List<DoctorAssessmentReportSummary>? reports,
    Object? reportNextCursor = asyncStateNoChange,
    bool? isReportLoading,
    bool? isLoadingMoreReports,
    bool? isGeneratingReport,
    Object? reportErrorMessage = asyncStateNoChange,
    Map<int, DoctorAssessmentReportDetail>? reportDetailCache,
    Set<int>? loadingReportDetailIds,
    Map<int, String>? reportDetailErrors,
    Object? selectedReportDetail = asyncStateNoChange,
  }) {
    return DoctorPatientDetailData(
      patient: patient ?? this.patient,
      patientProfile: identical(patientProfile, asyncStateNoChange)
          ? this.patientProfile
          : patientProfile as DoctorPatientProfile?,
      weightTrend: weightTrend ?? this.weightTrend,
      isBasicLoading: isBasicLoading ?? this.isBasicLoading,
      basicErrorMessage: identical(basicErrorMessage, asyncStateNoChange)
          ? this.basicErrorMessage
          : basicErrorMessage as String?,
      historyRecords: historyRecords ?? this.historyRecords,
      historyNextCursor: identical(historyNextCursor, asyncStateNoChange)
          ? this.historyNextCursor
          : historyNextCursor as String?,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      historyErrorMessage: identical(historyErrorMessage, asyncStateNoChange)
          ? this.historyErrorMessage
          : historyErrorMessage as String?,
      latestReport: identical(latestReport, asyncStateNoChange)
          ? this.latestReport
          : latestReport as DoctorAssessmentReportSummary?,
      reports: reports ?? this.reports,
      reportNextCursor: identical(reportNextCursor, asyncStateNoChange)
          ? this.reportNextCursor
          : reportNextCursor as String?,
      isReportLoading: isReportLoading ?? this.isReportLoading,
      isLoadingMoreReports: isLoadingMoreReports ?? this.isLoadingMoreReports,
      isGeneratingReport: isGeneratingReport ?? this.isGeneratingReport,
      reportErrorMessage: identical(reportErrorMessage, asyncStateNoChange)
          ? this.reportErrorMessage
          : reportErrorMessage as String?,
      reportDetailCache: reportDetailCache ?? this.reportDetailCache,
      loadingReportDetailIds:
          loadingReportDetailIds ?? this.loadingReportDetailIds,
      reportDetailErrors: reportDetailErrors ?? this.reportDetailErrors,
      selectedReportDetail: identical(selectedReportDetail, asyncStateNoChange)
          ? this.selectedReportDetail
          : selectedReportDetail as DoctorAssessmentReportDetail?,
    );
  }
}
