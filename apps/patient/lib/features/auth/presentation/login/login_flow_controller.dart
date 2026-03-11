import 'package:app_core/app_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/data/preference/const.dart';
import 'package:patient/features/auth/domain/entities/auth_entities.dart';
import 'package:patient/features/auth/presentation/login/login_flow_state.dart';
import 'package:patient/features/auth/presentation/providers/auth_providers.dart';
import 'package:patient/features/user/presentation/providers/user_providers.dart';

final loginFlowControllerProvider =
    StateNotifierProvider.autoDispose<LoginFlowController, LoginFlowState>((
      ref,
    ) {
      return LoginFlowController(ref);
    });

final class LoginFlowController
    extends BaseLoginFlowController<AuthSessionResult> {
  LoginFlowController(this._ref);

  final Ref _ref;

  @override
  Future<Result<LoginCheckResult>> loginCheck(String phone) {
    return _ref.read(loginCheckUseCaseProvider).execute(phone);
  }

  @override
  Future<Result<void>> sendRegisterCodeRequest(String phone) {
    return _ref
        .read(sendSmsCodeUseCaseProvider)
        .execute(phone: phone, purpose: SmsPurpose.register);
  }

  @override
  Future<Result<AuthSessionResult>> loginDirectRequest({
    required String phone,
    required String ticket,
  }) {
    return _ref
        .read(loginDirectUseCaseProvider)
        .execute(phone: phone, ticket: ticket);
  }

  @override
  Future<Result<AuthSessionResult>> loginPasswordRequest({
    required String phone,
    required String password,
  }) {
    return _ref
        .read(loginPasswordUseCaseProvider)
        .execute(phone: phone, password: password);
  }

  @override
  Future<Result<AuthSessionResult>> registerRequest({
    required String phone,
    required String smsCode,
    required String password,
  }) {
    return _ref
        .read(registerUseCaseProvider)
        .execute(phone: phone, smsCode: smsCode, password: password);
  }

  @override
  Future<void> onAuthSucceeded(
    AuthSessionResult session,
    LoginFlowMode mode,
  ) async {
    if (mode == LoginFlowMode.register) {
      await AppPrefs.hasCompletedFirstLogin.set(false);
    }
    await _warmUpProfileCaches();
  }

  Future<void> _warmUpProfileCaches() async {
    try {
      await Future.wait([
        _ref.read(avatarWarmupServiceProvider).warmUp(),
        _ref.read(basicProfileWarmupServiceProvider).warmUp(),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Ignore warm-up failures to avoid blocking login flow.
    }
  }
}
