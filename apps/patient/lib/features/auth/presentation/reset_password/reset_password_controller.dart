import 'package:app_core/app_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/features/auth/domain/entities/auth_entities.dart';
import 'package:patient/features/auth/presentation/providers/auth_providers.dart';
import 'package:patient/features/auth/presentation/reset_password/reset_password_state.dart';

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordController,
      ResetPasswordState
    >((ref) {
      return ResetPasswordController(ref);
    });

final class ResetPasswordController extends BaseResetPasswordFlowController {
  ResetPasswordController(this._ref);

  final Ref _ref;

  @override
  Future<Result<void>> sendResetCodeRequest(String phone) {
    return _ref
        .read(sendSmsCodeUseCaseProvider)
        .execute(phone: phone, purpose: SmsPurpose.resetPassword);
  }

  @override
  Future<Result<void>> resetPasswordRequest({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) {
    return _ref
        .read(resetPasswordUseCaseProvider)
        .execute(phone: phone, smsCode: smsCode, newPassword: newPassword);
  }
}
