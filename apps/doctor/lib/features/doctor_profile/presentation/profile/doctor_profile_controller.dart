import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_state.dart';
import 'package:doctor/features/doctor_profile/presentation/providers/doctor_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorProfileControllerProvider =
    StateNotifierProvider<DoctorProfileController, DoctorProfileState>((ref) {
  return DoctorProfileController(ref);
});

final class DoctorProfileController extends StateNotifier<DoctorProfileState> {
  DoctorProfileController(this._ref) : super(const DoctorProfileState());

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final profileResult = await _ref.read(fetchDoctorProfileUseCaseProvider).execute();
    final thresholdResult = await _ref.read(fetchDoctorThresholdsUseCaseProvider).execute();

    if (profileResult case Failure<DoctorProfile>(error: final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return;
    }
    if (thresholdResult case Failure<DoctorThresholds>(error: final error)) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return;
    }

    final profile = (profileResult as Success<DoctorProfile>).data;
    final thresholds = (thresholdResult as Success<DoctorThresholds>).data;
    state = state.copyWith(
      isLoading: false,
      profile: profile,
      thresholds: thresholds,
      errorMessage: null,
    );
  }

  Future<String?> updateThresholds(DoctorThresholds payload) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(updateDoctorThresholdsUseCaseProvider).execute(payload);
    switch (result) {
      case Success<DoctorThresholds>(data: final data):
        state = state.copyWith(isLoading: false, thresholds: data);
        return null;
      case Failure<DoctorThresholds>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return error.message;
    }
  }
}
