import 'package:app_core/app_core.dart';
import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_state.dart';
import 'package:doctor/features/doctor_profile/presentation/providers/doctor_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorProfileControllerProvider =
    StateNotifierProvider<DoctorProfileController, DoctorProfileState>((ref) {
      return DoctorProfileController(ref);
    });

final class DoctorProfileController extends AsyncController<DoctorProfileData> {
  DoctorProfileController(this._ref)
    : super(const AsyncState<DoctorProfileData>(data: DoctorProfileData()));

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final profileResult = await _ref
        .read(fetchDoctorProfileUseCaseProvider)
        .execute();
    final thresholdResult = await _ref
        .read(fetchDoctorThresholdsUseCaseProvider)
        .execute();

    var nextData = state.data;
    String? errorMessage;

    switch (profileResult) {
      case Success<DoctorProfile>(data: final profile):
        nextData = nextData.copyWith(profile: profile);
      case Failure<DoctorProfile>(error: final error):
        errorMessage = error.message;
    }

    switch (thresholdResult) {
      case Success<DoctorThresholds>(data: final thresholds):
        nextData = nextData.copyWith(thresholds: thresholds);
      case Failure<DoctorThresholds>(error: final error):
        errorMessage ??= error.message;
    }

    state = state.copyWith(
      isLoading: false,
      data: nextData,
      errorMessage: errorMessage,
    );
  }

  Future<String?> updateProfile(DoctorProfileUpdatePayload payload) {
    return runAction<DoctorProfile>(
      request: () =>
          _ref.read(updateDoctorProfileUseCaseProvider).execute(payload),
      onSuccess: (current, profile) => current.copyWith(profile: profile),
    );
  }

  Future<String?> updateThresholds(DoctorThresholds payload) {
    return runAction<DoctorThresholds>(
      request: () =>
          _ref.read(updateDoctorThresholdsUseCaseProvider).execute(payload),
      onSuccess: (current, thresholds) =>
          current.copyWith(thresholds: thresholds),
    );
  }
}
