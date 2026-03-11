import 'package:app_core/app_core.dart';
import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_monitor/presentation/monitor/doctor_monitor_state.dart';
import 'package:doctor/features/doctor_monitor/presentation/providers/doctor_monitor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorMonitorControllerProvider =
    StateNotifierProvider<DoctorMonitorController, DoctorMonitorState>((ref) {
      return DoctorMonitorController(ref);
    });

final class DoctorMonitorController extends AsyncController<DoctorMonitorData> {
  DoctorMonitorController(this._ref)
    : super(const AsyncState<DoctorMonitorData>(data: DoctorMonitorData()));

  final Ref _ref;

  Future<void> refresh({required int patientUserId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final summaryResult = await _ref
        .read(fetchDoctorSideEffectSummaryUseCaseProvider)
        .execute(patientUserId: patientUserId);
    final weightResult = await _ref
        .read(fetchDoctorWeightTrendUseCaseProvider)
        .execute(patientUserId: patientUserId);

    if (summaryResult case Failure<List<SideEffectSummaryItem>>(
      error: final error,
    )) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return;
    }
    if (weightResult case Failure<List<WeightTrendPoint>>(error: final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return;
    }

    state = state.copyWith(
      isLoading: false,
      data: state.data.copyWith(
        summary: (summaryResult as Success<List<SideEffectSummaryItem>>).data,
        weightTrend: (weightResult as Success<List<WeightTrendPoint>>).data,
      ),
      errorMessage: null,
    );
  }
}
