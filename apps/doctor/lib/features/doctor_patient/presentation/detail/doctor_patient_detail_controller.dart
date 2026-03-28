import 'package:app_core/app_core.dart';
import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_monitor/presentation/providers/doctor_monitor_providers.dart';
import 'package:doctor/features/doctor_patient/presentation/detail/doctor_patient_detail_args.dart';
import 'package:doctor/features/doctor_patient/presentation/detail/doctor_patient_detail_state.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/presentation/providers/doctor_scale_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorPatientDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<
      DoctorPatientDetailController,
      DoctorPatientDetailState,
      DoctorPatientDetailArgs
    >((ref, args) {
      return DoctorPatientDetailController(ref, args);
    });

final class DoctorPatientDetailController
    extends AsyncController<DoctorPatientDetailData> {
  DoctorPatientDetailController(this._ref, this._args)
    : super(
        AsyncState<DoctorPatientDetailData>(
          data: DoctorPatientDetailData(patient: _args.patient),
        ),
      );

  final Ref _ref;
  final DoctorPatientDetailArgs _args;
  static const int _historyPageSize = 20;
  static const int _reportPageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await refreshBasicTab();
    await refreshHistoryTab(reset: true);
    await refreshReportTab(resetList: true);
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshBasicTab() async {
    final patientUserId = _args.patient.patientUserId;
    final currentData = state.data;
    state = state.copyWith(
      errorMessage: null,
      data: currentData.copyWith(isBasicLoading: true, basicErrorMessage: null),
    );

    final profileFuture = _ref
        .read(fetchDoctorPatientProfileUseCaseProvider)
        .execute(patientUserId: patientUserId);
    final weightFuture = _ref
        .read(fetchDoctorWeightTrendUseCaseProvider)
        .execute(patientUserId: patientUserId);

    final profileResult = await profileFuture;
    final weightResult = await weightFuture;

    String? errorMessage;
    var patientProfile = state.data.patientProfile;
    var weightTrend = state.data.weightTrend;

    switch (profileResult) {
      case Success(data: final data):
        patientProfile = data;
      case Failure(error: final error):
        errorMessage ??= error.message;
    }
    switch (weightResult) {
      case Success<List<WeightTrendPoint>>(data: final data):
        weightTrend = data;
      case Failure<List<WeightTrendPoint>>(error: final error):
        if (error.type == AppErrorType.notFound) {
          weightTrend = const <WeightTrendPoint>[];
        } else {
          errorMessage ??= error.message;
        }
    }

    state = state.copyWith(
      data: state.data.copyWith(
        patientProfile: patientProfile,
        weightTrend: weightTrend,
        isBasicLoading: false,
        basicErrorMessage: errorMessage,
      ),
    );
  }

  Future<void> refreshHistoryTab({bool reset = true}) async {
    final currentData = state.data;
    state = state.copyWith(
      errorMessage: null,
      data: currentData.copyWith(
        isHistoryLoading: true,
        isLoadingMoreHistory: false,
        historyErrorMessage: null,
        historyRecords: reset ? const <DoctorScaleAnswerRecord>[] : null,
        historyNextCursor: reset ? null : asyncStateNoChange,
      ),
    );

    final result = await _ref
        .read(fetchDoctorScaleAnswerRecordsUseCaseProvider)
        .execute(
          patientUserId: _args.patient.patientUserId,
          limit: _historyPageSize,
        );

    result.when(
      success: (data) {
        state = state.copyWith(
          data: state.data.copyWith(
            historyRecords: _sortHistoryRecords(data.items),
            historyNextCursor: data.nextCursor,
            isHistoryLoading: false,
            isLoadingMoreHistory: false,
            historyErrorMessage: null,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          data: state.data.copyWith(
            historyRecords: error.type == AppErrorType.notFound
                ? const <DoctorScaleAnswerRecord>[]
                : state.data.historyRecords,
            historyNextCursor: error.type == AppErrorType.notFound
                ? null
                : state.data.historyNextCursor,
            isHistoryLoading: false,
            isLoadingMoreHistory: false,
            historyErrorMessage: error.type == AppErrorType.notFound
                ? null
                : error.message,
          ),
        );
      },
    );
  }

  Future<void> loadMoreHistory() async {
    final currentData = state.data;
    if (state.isLoading ||
        currentData.isHistoryLoading ||
        currentData.isLoadingMoreHistory ||
        !currentData.hasMoreHistory) {
      return;
    }

    state = state.copyWith(
      data: currentData.copyWith(
        isLoadingMoreHistory: true,
        historyErrorMessage: null,
      ),
    );

    final result = await _ref
        .read(fetchDoctorScaleAnswerRecordsUseCaseProvider)
        .execute(
          patientUserId: _args.patient.patientUserId,
          limit: _historyPageSize,
          cursor: currentData.historyNextCursor,
        );

    result.when(
      success: (data) {
        state = state.copyWith(
          data: state.data.copyWith(
            historyRecords: _sortHistoryRecords(
              _mergeHistoryRecords(state.data.historyRecords, data.items),
            ),
            historyNextCursor: data.nextCursor,
            isLoadingMoreHistory: false,
            historyErrorMessage: null,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          data: state.data.copyWith(
            isLoadingMoreHistory: false,
            historyErrorMessage: error.message,
          ),
        );
      },
    );
  }

  Future<void> refreshReportTab({bool resetList = true}) async {
    final currentData = state.data;
    state = state.copyWith(
      errorMessage: null,
      data: currentData.copyWith(
        isReportLoading: true,
        isLoadingMoreReports: false,
        reportErrorMessage: null,
        reports: resetList ? const <DoctorAssessmentReportSummary>[] : null,
        reportNextCursor: resetList ? null : asyncStateNoChange,
      ),
    );

    final latestFuture = _ref
        .read(fetchDoctorLatestAssessmentReportUseCaseProvider)
        .execute(patientUserId: _args.patient.patientUserId);
    final latestResult = await latestFuture;

    String? errorMessage;
    DoctorAssessmentReportSummary? latestReport;
    switch (latestResult) {
      case Success<DoctorAssessmentReportSummary>(data: final data):
        latestReport = data;
      case Failure<DoctorAssessmentReportSummary>(error: final error):
        if (error.type != AppErrorType.notFound) {
          errorMessage ??= error.message;
        }
    }

    var reports = state.data.reports;
    var nextCursor = state.data.reportNextCursor;
    if (resetList) {
      final listResult = await _ref
          .read(fetchDoctorAssessmentReportsUseCaseProvider)
          .execute(
            patientUserId: _args.patient.patientUserId,
            limit: _reportPageSize,
          );
      switch (listResult) {
        case Success<DoctorAssessmentReportListResult>(data: final data):
          reports = _sortReports(data.items);
          nextCursor = data.nextCursor;
        case Failure<DoctorAssessmentReportListResult>(error: final error):
          if (error.type == AppErrorType.notFound) {
            reports = const <DoctorAssessmentReportSummary>[];
            nextCursor = null;
          } else {
            errorMessage ??= error.message;
          }
      }
    }

    state = state.copyWith(
      data: state.data.copyWith(
        latestReport: latestReport,
        reports: reports,
        reportNextCursor: nextCursor,
        isReportLoading: false,
        isLoadingMoreReports: false,
        reportErrorMessage: errorMessage,
      ),
    );
  }

  Future<void> loadMoreReports() async {
    final currentData = state.data;
    if (state.isLoading ||
        currentData.isReportLoading ||
        currentData.isLoadingMoreReports ||
        !currentData.hasMoreReports) {
      return;
    }

    state = state.copyWith(
      data: currentData.copyWith(
        isLoadingMoreReports: true,
        reportErrorMessage: null,
      ),
    );

    final result = await _ref
        .read(fetchDoctorAssessmentReportsUseCaseProvider)
        .execute(
          patientUserId: _args.patient.patientUserId,
          limit: _reportPageSize,
          cursor: currentData.reportNextCursor,
        );

    result.when(
      success: (data) {
        state = state.copyWith(
          data: state.data.copyWith(
            reports: _mergeReports(state.data.reports, data.items),
            reportNextCursor: data.nextCursor,
            isLoadingMoreReports: false,
            reportErrorMessage: null,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          data: state.data.copyWith(
            isLoadingMoreReports: false,
            reportErrorMessage: error.message,
          ),
        );
      },
    );
  }

  Future<DoctorAssessmentReportDetail?> openReportDetail({
    required int reportId,
  }) async {
    final cached = state.data.reportDetailCache[reportId];
    if (cached != null) {
      state = state.copyWith(
        data: state.data.copyWith(selectedReportDetail: cached),
      );
      return cached;
    }
    await _loadReportDetail(reportId: reportId, setSelected: true);
    return state.data.selectedReportDetail?.reportId == reportId
        ? state.data.selectedReportDetail
        : null;
  }

  Future<void> retryReportDetail({required int reportId}) async {
    await _loadReportDetail(reportId: reportId);
  }

  Future<String?> generateReport() async {
    state = state.copyWith(
      data: state.data.copyWith(
        isGeneratingReport: true,
        reportErrorMessage: null,
      ),
    );

    final result = await _ref
        .read(generateDoctorAssessmentReportUseCaseProvider)
        .execute(patientUserId: _args.patient.patientUserId);
    final message = result.when(
      success: (_) => null,
      failure: (error) => error.message,
    );

    state = state.copyWith(
      data: state.data.copyWith(
        isGeneratingReport: false,
        reportErrorMessage: message,
      ),
    );

    if (message == null) {
      await refreshReportTab(resetList: true);
    }
    return message;
  }

  Future<void> _loadReportDetail({
    required int reportId,
    bool setSelected = false,
  }) async {
    final nextLoading = <int>{...state.data.loadingReportDetailIds, reportId};
    final nextErrors = <int, String>{...state.data.reportDetailErrors}
      ..remove(reportId);
    state = state.copyWith(
      data: state.data.copyWith(
        loadingReportDetailIds: nextLoading,
        reportDetailErrors: nextErrors,
      ),
    );

    final result = await _ref
        .read(fetchDoctorAssessmentReportDetailUseCaseProvider)
        .execute(
          patientUserId: _args.patient.patientUserId,
          reportId: reportId,
        );
    result.when(
      success: (detail) {
        final loading = <int>{...state.data.loadingReportDetailIds}
          ..remove(reportId);
        final cache = <int, DoctorAssessmentReportDetail>{
          ...state.data.reportDetailCache,
          reportId: detail,
        };
        final errors = <int, String>{...state.data.reportDetailErrors}
          ..remove(reportId);
        state = state.copyWith(
          data: state.data.copyWith(
            reportDetailCache: cache,
            loadingReportDetailIds: loading,
            reportDetailErrors: errors,
            selectedReportDetail: setSelected ? detail : asyncStateNoChange,
          ),
        );
      },
      failure: (error) {
        final loading = <int>{...state.data.loadingReportDetailIds}
          ..remove(reportId);
        final errors = <int, String>{
          ...state.data.reportDetailErrors,
          reportId: error.message,
        };
        state = state.copyWith(
          data: state.data.copyWith(
            loadingReportDetailIds: loading,
            reportDetailErrors: errors,
            selectedReportDetail: setSelected ? null : asyncStateNoChange,
          ),
        );
      },
    );
  }

  List<DoctorScaleAnswerRecord> _mergeHistoryRecords(
    List<DoctorScaleAnswerRecord> current,
    List<DoctorScaleAnswerRecord> incoming,
  ) {
    final map = <int, DoctorScaleAnswerRecord>{
      for (final item in current) item.recordId: item,
    };
    for (final item in incoming) {
      map[item.recordId] = item;
    }
    return map.values.toList(growable: false);
  }

  List<DoctorScaleAnswerRecord> _sortHistoryRecords(
    List<DoctorScaleAnswerRecord> source,
  ) {
    final sorted = source.toList(growable: false);
    sorted.sort((a, b) {
      final left = a.answeredAt;
      final right = b.answeredAt;
      if (left == null && right == null) {
        return b.recordId.compareTo(a.recordId);
      }
      if (left == null) return 1;
      if (right == null) return -1;
      final timeCompare = right.compareTo(left);
      if (timeCompare != 0) return timeCompare;
      return b.recordId.compareTo(a.recordId);
    });
    return sorted;
  }

  List<DoctorAssessmentReportSummary> _mergeReports(
    List<DoctorAssessmentReportSummary> current,
    List<DoctorAssessmentReportSummary> incoming,
  ) {
    final map = <int, DoctorAssessmentReportSummary>{
      for (final item in current) item.reportId: item,
    };
    for (final item in incoming) {
      map[item.reportId] = item;
    }
    return _sortReports(map.values.toList(growable: false));
  }

  List<DoctorAssessmentReportSummary> _sortReports(
    List<DoctorAssessmentReportSummary> source,
  ) {
    final sorted = source.toList(growable: false);
    sorted.sort((a, b) {
      final left = a.generatedAt;
      final right = b.generatedAt;
      if (left == null && right == null) {
        return b.reportId.compareTo(a.reportId);
      }
      if (left == null) return 1;
      if (right == null) return -1;
      final timeCompare = right.compareTo(left);
      if (timeCompare != 0) return timeCompare;
      return b.reportId.compareTo(a.reportId);
    });
    return sorted;
  }
}
