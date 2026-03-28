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
    final showFullLoading = shouldResetItems || previousData.items.isEmpty;

    state = state.copyWith(
      isLoading: showFullLoading,
      errorMessage: null,
      data: previousData.copyWith(
        query: targetQuery,
        items: shouldResetItems ? const <DoctorPatient>[] : previousData.items,
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
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          data: state.data.copyWith(
            items: data.items,
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
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(
            items: _mergeByPatientUserId(state.data.items, data.items),
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
        state = state.copyWith(
          errorMessage: null,
          data: state.data.copyWith(
            items: [
              for (final patient in state.data.items)
                if (patient.patientUserId == patientUserId)
                  patient.copyWith(severityGroup: data.severityGroup)
                else
                  patient,
            ],
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
}
