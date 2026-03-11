import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/features/doctor_auth/presentation/login/doctor_login_flow_state.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart' show LoginFlowMode;

final doctorLoginFlowControllerProvider =
    StateNotifierProvider.autoDispose<
      DoctorLoginFlowController,
      DoctorLoginFlowState
    >((ref) {
      return DoctorLoginFlowController(ref);
    });

final class DoctorLoginFlowController
    extends BaseLoginFlowController<DoctorAuthSessionResult> {
  DoctorLoginFlowController(this._ref);

  final Ref _ref;

  @override
  Future<Result<DoctorLoginCheckResult>> loginCheck(String phone) {
    return _ref.read(doctorLoginCheckUseCaseProvider).execute(phone);
  }

  @override
  Future<Result<void>> sendRegisterCodeRequest(String phone) {
    return _ref
        .read(sendDoctorSmsCodeUseCaseProvider)
        .execute(phone: phone, purpose: DoctorSmsPurpose.register);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginDirectRequest({
    required String phone,
    required String ticket,
  }) {
    return _ref
        .read(doctorLoginDirectUseCaseProvider)
        .execute(phone: phone, ticket: ticket);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginPasswordRequest({
    required String phone,
    required String password,
  }) {
    return _ref
        .read(doctorLoginPasswordUseCaseProvider)
        .execute(phone: phone, password: password);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> registerRequest({
    required String phone,
    required String smsCode,
    required String password,
  }) {
    return _ref
        .read(doctorRegisterUseCaseProvider)
        .execute(phone: phone, smsCode: smsCode, password: password);
  }

  @override
  Future<void> onAuthSucceeded(
    DoctorAuthSessionResult session,
    LoginFlowMode mode,
  ) async {
    _ref.read(doctorAuthControllerProvider.notifier).setSession(session);
  }
}
