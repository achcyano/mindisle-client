import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_state.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorAuthControllerProvider =
    StateNotifierProvider<DoctorAuthController, DoctorAuthState>((ref) {
  return DoctorAuthController(ref);
});

final class DoctorAuthController extends StateNotifier<DoctorAuthState> {
  DoctorAuthController(this._ref) : super(const DoctorAuthState());

  final Ref _ref;

  Future<String?> loginPassword({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref
        .read(doctorLoginPasswordUseCaseProvider)
        .execute(phone: phone, password: password);
    return _consumeSessionResult(result);
  }

  Future<String?> register({
    required String phone,
    required String smsCode,
    required String password,
    required String fullName,
    String? title,
    String? hospital,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(doctorRegisterUseCaseProvider).execute(
          phone: phone,
          smsCode: smsCode,
          password: password,
          fullName: fullName,
          title: title,
          hospital: hospital,
        );
    return _consumeSessionResult(result);
  }

  Future<String?> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref
        .read(sendDoctorSmsCodeUseCaseProvider)
        .execute(phone: phone, purpose: purpose);
    return _consumeVoidResult(result, successMessage: '验证码发送成功');
  }

  Future<String?> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(doctorResetPasswordUseCaseProvider).execute(
          phone: phone,
          smsCode: smsCode,
          newPassword: newPassword,
        );
    return _consumeVoidResult(result, successMessage: '重置成功');
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(doctorChangePasswordUseCaseProvider).execute(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
    return _consumeVoidResult(result, successMessage: '修改成功');
  }

  Future<String?> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(doctorLogoutUseCaseProvider).execute();
    final message = _consumeVoidResult(result, successMessage: '已退出');
    if (message == '已退出') {
      state = state.copyWith(lastSession: null);
    }
    return message;
  }

  String? _consumeSessionResult(Result<DoctorAuthSession> result) {
    return switch (result) {
      Success<DoctorAuthSession>(data: final data) => _onSessionSuccess(data),
      Failure<DoctorAuthSession>(error: final error) => _onFailure(error.message),
    };
  }

  String? _consumeVoidResult(Result<void> result, {required String successMessage}) {
    return switch (result) {
      Success<void>() => _onVoidSuccess(successMessage),
      Failure<void>(error: final error) => _onFailure(error.message),
    };
  }

  String _onSessionSuccess(DoctorAuthSession session) {
    state = state.copyWith(isLoading: false, lastSession: session, errorMessage: null);
    return '登录成功';
  }

  String _onVoidSuccess(String message) {
    state = state.copyWith(isLoading: false, errorMessage: null);
    return message;
  }

  String _onFailure(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
    return message;
  }
}
