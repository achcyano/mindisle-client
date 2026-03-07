import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_state.dart';
import 'package:doctor/features/doctor_binding/presentation/providers/doctor_binding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorBindingControllerProvider =
    StateNotifierProvider<DoctorBindingController, DoctorBindingState>((ref) {
  return DoctorBindingController(ref);
});

final class DoctorBindingController extends StateNotifier<DoctorBindingState> {
  DoctorBindingController(this._ref) : super(const DoctorBindingState());

  final Ref _ref;

  Future<void> refreshHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(fetchDoctorBindingHistoryUseCaseProvider).execute(limit: 50);
    switch (result) {
      case Success<DoctorBindingHistoryResult>(data: final data):
        state = state.copyWith(isLoading: false, history: data.items);
      case Failure<DoctorBindingHistoryResult>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<String?> createCode() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(createDoctorBindingCodeUseCaseProvider).execute();
    switch (result) {
      case Success<DoctorBindingCode>(data: final data):
        state = state.copyWith(isLoading: false, latestCode: data);
        return null;
      case Failure<DoctorBindingCode>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return error.message;
    }
  }
}
