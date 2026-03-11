import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorAuthControllerProvider =
    StateNotifierProvider<DoctorAuthController, DoctorAuthState>((ref) {
      return DoctorAuthController();
    });

final class DoctorAuthController extends StateNotifier<DoctorAuthState> {
  DoctorAuthController() : super(const DoctorAuthState());

  void setSession(DoctorAuthSessionResult session) {
    state = state.copyWith(session: session, isInitialized: true);
  }

  void clearSession() {
    state = state.copyWith(session: null, isInitialized: true);
  }

  void markInitialized() {
    state = state.copyWith(isInitialized: true);
  }
}
