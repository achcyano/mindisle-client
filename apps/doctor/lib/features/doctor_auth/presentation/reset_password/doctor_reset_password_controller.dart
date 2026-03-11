import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:doctor/features/doctor_auth/presentation/reset_password/doctor_reset_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorResetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      DoctorResetPasswordController,
      DoctorResetPasswordState
    >((ref) {
      return DoctorResetPasswordController(ref);
    });

final class DoctorResetPasswordController
    extends BaseResetPasswordFlowController {
  DoctorResetPasswordController(this._ref);

  final Ref _ref;

  @override
  Future<Result<void>> sendResetCodeRequest(String phone) {
    return _ref
        .read(sendDoctorSmsCodeUseCaseProvider)
        .execute(phone: phone, purpose: DoctorSmsPurpose.resetPassword);
  }

  @override
  Future<Result<void>> resetPasswordRequest({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) {
    return _ref
        .read(doctorResetPasswordUseCaseProvider)
        .execute(phone: phone, smsCode: smsCode, newPassword: newPassword);
  }
}
