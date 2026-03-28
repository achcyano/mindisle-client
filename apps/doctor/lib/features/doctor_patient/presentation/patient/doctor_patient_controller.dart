import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_state.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorPatientControllerProvider =
    StateNotifierProvider<DoctorPatientController, DoctorPatientState>((ref) {
      return DoctorPatientController(ref);
    });

final class DoctorPatientController extends AsyncController<DoctorPatientData> {
  DoctorPatientController(this._ref)
    : super(const AsyncState<DoctorPatientData>(data: DoctorPatientData()));

  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh({
    DoctorPatientQuery? query,
    bool clearItems = false,
  }) async {
    final previousData = state.data;
    final targetQuery = query ?? previousData.query;
    final shouldResetItems = clearItems || !previousData.hasLoaded;
    final showFullLoading =
        shouldResetItems || previousData.sourceItems.isEmpty;

    state = state.copyWith(
      isLoading: showFullLoading,
      errorMessage: null,
      data: previousData.copyWith(
        query: targetQuery,
        items: shouldResetItems ? const <DoctorPatient>[] : previousData.items,
        sourceItems: shouldResetItems
            ? const <DoctorPatient>[]
            : previousData.sourceItems,
        nextCursor: shouldResetItems ? null : previousData.nextCursor,
        isRefreshing: !showFullLoading,
        isLoadingMore: false,
      ),
    );

    final result = await _ref
        .read(fetchDoctorPatientsUseCaseProvider)
        .execute(query: targetQuery, limit: _pageSize);

    result.when(
      success: (data) {
        final visibleItems = _applyDiagnosisFilter(
          data.items,
          targetQuery.diagnosisKeyword,
        );
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          data: state.data.copyWith(
            sourceItems: data.items,
            items: visibleItems,
            nextCursor: data.nextCursor,
            isRefreshing: false,
            isLoadingMore: false,
            hasLoaded: true,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.message,
          data: state.data.copyWith(
            isRefreshing: false,
            isLoadingMore: false,
            hasLoaded: true,
          ),
        );
      },
    );
  }

  Future<void> applyQuery(DoctorPatientQuery query) {
    final current = state.data.query;
    if (current.isRemoteEqualTo(query)) {
      state = state.copyWith(
        errorMessage: null,
        data: state.data.copyWith(
          query: query,
          items: _applyDiagnosisFilter(
            state.data.sourceItems,
            query.diagnosisKeyword,
          ),
        ),
      );
      return Future.value();
    }
    return refresh(query: query, clearItems: true);
  }

  Future<void> loadMore() async {
    final currentData = state.data;
    if (state.isLoading ||
        currentData.isRefreshing ||
        currentData.isLoadingMore ||
        !currentData.hasMore) {
      return;
    }

    state = state.copyWith(
      errorMessage: null,
      data: currentData.copyWith(isLoadingMore: true),
    );

    final result = await _ref
        .read(fetchDoctorPatientsUseCaseProvider)
        .execute(
          query: currentData.query,
          limit: _pageSize,
          cursor: currentData.nextCursor,
        );

    result.when(
      success: (data) {
        final mergedItems = _mergeByPatientUserId(
          state.data.sourceItems,
          data.items,
        );
        final visibleItems = _applyDiagnosisFilter(
          mergedItems,
          state.data.query.diagnosisKeyword,
        );
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(
            sourceItems: mergedItems,
            items: visibleItems,
            nextCursor: data.nextCursor,
            isLoadingMore: false,
            hasLoaded: true,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          errorMessage: error.message,
          data: state.data.copyWith(isLoadingMore: false),
        );
      },
    );
  }

  Future<String?> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) async {
    final result = await _ref
        .read(updateDoctorPatientGroupingUseCaseProvider)
        .execute(patientUserId: patientUserId, payload: payload);

    return result.when(
      success: (data) {
        final updated = _updatePatient(
          state.data.sourceItems,
          patientUserId: patientUserId,
          updater: (patient) =>
              patient.copyWith(severityGroup: data.severityGroup),
        );
        final visibleItems = _applyDiagnosisFilter(
          updated,
          state.data.query.diagnosisKeyword,
        );
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(
            sourceItems: updated,
            items: visibleItems,
            groupOptions: _mergeGroupOption(
              state.data.groupOptions,
              data.severityGroup,
            ),
          ),
        );
        return null;
      },
      failure: (error) {
        state = state.copyWith(errorMessage: error.message);
        return error.message;
      },
    );
  }

  Future<void> loadGroupOptions({bool force = false}) async {
    final currentData = state.data;
    if (currentData.isLoadingGroups) return;
    if (!force && currentData.groupOptions.isNotEmpty) return;

    state = state.copyWith(data: currentData.copyWith(isLoadingGroups: true));

    final result = await _ref
        .read(fetchDoctorPatientGroupsUseCaseProvider)
        .execute();
    result.when(
      success: (groups) {
        state = state.copyWith(
          data: state.data.copyWith(
            groupOptions: _sortGroupOptions(groups),
            isLoadingGroups: false,
          ),
        );
      },
      failure: (error) {
        state = state.copyWith(
          data: state.data.copyWith(isLoadingGroups: false),
          errorMessage: error.message,
        );
      },
    );
  }

  Future<String?> createGroup({required String severityGroup}) async {
    final normalized = severityGroup.trim();
    if (normalized.isEmpty) {
      return '分组名称不能为空';
    }
    final result = await _ref
        .read(createDoctorPatientGroupUseCaseProvider)
        .execute(severityGroup: normalized);
    return result.when(
      success: (group) {
        final merged = _mergeGroupOption(
          state.data.groupOptions,
          group.severityGroup,
          patientCount: group.patientCount,
        );
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(groupOptions: merged),
        );
        return null;
      },
      failure: (error) {
        state = state.copyWith(errorMessage: error.message);
        return error.message;
      },
    );
  }

  Future<String?> updateDiagnosis({
    required int patientUserId,
    required DoctorPatientDiagnosisUpdatePayload payload,
  }) async {
    final result = await _ref
        .read(updateDoctorPatientDiagnosisUseCaseProvider)
        .execute(patientUserId: patientUserId, payload: payload);
    return result.when(
      success: (data) {
        final updated = _updatePatient(
          state.data.sourceItems,
          patientUserId: patientUserId,
          updater: (patient) => patient.copyWith(diagnosis: data.diagnosis),
        );
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(
            sourceItems: updated,
            items: _applyDiagnosisFilter(
              updated,
              state.data.query.diagnosisKeyword,
            ),
          ),
        );
        return null;
      },
      failure: (error) {
        state = state.copyWith(errorMessage: error.message);
        return error.message;
      },
    );
  }

  List<DoctorPatient> _mergeByPatientUserId(
    List<DoctorPatient> current,
    List<DoctorPatient> incoming,
  ) {
    final map = <int, DoctorPatient>{
      for (final item in current) item.patientUserId: item,
    };
    for (final item in incoming) {
      map[item.patientUserId] = item;
    }
    return map.values.toList(growable: false);
  }

  List<DoctorPatient> _updatePatient(
    List<DoctorPatient> source, {
    required int patientUserId,
    required DoctorPatient Function(DoctorPatient patient) updater,
  }) {
    return [
      for (final patient in source)
        if (patient.patientUserId == patientUserId)
          updater(patient)
        else
          patient,
    ];
  }

  List<DoctorPatient> _applyDiagnosisFilter(
    List<DoctorPatient> source,
    String? diagnosisKeyword,
  ) {
    final normalized = diagnosisKeyword?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return source;
    }
    return [
      for (final patient in source)
        if ((patient.diagnosis ?? '').trim().toLowerCase().contains(normalized))
          patient,
    ];
  }

  List<DoctorPatientGroupOption> _mergeGroupOption(
    List<DoctorPatientGroupOption> source,
    String? severityGroup, {
    int patientCount = 0,
  }) {
    final normalized = severityGroup?.trim();
    if (normalized == null || normalized.isEmpty) {
      return source;
    }
    final existingIndex = source.indexWhere(
      (item) => item.severityGroup == normalized,
    );
    if (existingIndex < 0) {
      return _sortGroupOptions([
        ...source,
        DoctorPatientGroupOption(
          severityGroup: normalized,
          patientCount: patientCount,
        ),
      ]);
    }

    final existing = source[existingIndex];
    final next = source.toList(growable: false);
    next[existingIndex] = DoctorPatientGroupOption(
      severityGroup: existing.severityGroup,
      patientCount: existing.patientCount > 0
          ? existing.patientCount
          : patientCount,
    );
    return _sortGroupOptions(next);
  }

  List<DoctorPatientGroupOption> _sortGroupOptions(
    List<DoctorPatientGroupOption> input,
  ) {
    final sorted = input.toList(growable: false);
    sorted.sort((a, b) {
      final countCompare = b.patientCount.compareTo(a.patientCount);
      if (countCompare != 0) return countCompare;
      return a.severityGroup.compareTo(b.severityGroup);
    });
    return sorted;
  }
}
