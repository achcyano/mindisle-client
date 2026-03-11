import 'dart:async';

import 'package:app_core/src/result/app_error.dart';
import 'package:app_core/src/result/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

abstract class BaseResetPasswordFlowController
    extends StateNotifier<ResetPasswordState> {
  BaseResetPasswordFlowController() : super(const ResetPasswordState());

  static const int resendCooldownSeconds = 60;

  Timer? _resendCooldownTimer;

  Future<Result<void>> sendResetCodeRequest(String phone);

  Future<Result<void>> resetPasswordRequest({
    required String phone,
    required String smsCode,
    required String newPassword,
  });

  bool isOtpInvalidError(AppError error) {
    return error.code == 40003 ||
        error.code == 42903 ||
        (error.code == 50010 && error.message.contains('验证码'));
  }

  void initialize({required String phone}) {
    _cancelResendCooldownTimer();
    state = ResetPasswordState(phone: phone.trim());
  }

  void inputOtpDigit(String digit) {
    if (state.step != ResetPasswordStep.otp) return;
    if (state.isSubmitting || state.isSendingCode) return;
    if (!_isDigit(digit) || state.otpDigits.length >= 6) return;

    state = state.copyWith(
      otpDigits: state.otpDigits + digit,
      inlineError: null,
    );
  }

  void deleteOtpDigit() {
    if (state.step != ResetPasswordStep.otp) return;
    if (state.isSubmitting || state.isSendingCode) return;
    if (state.otpDigits.isEmpty) return;

    state = state.copyWith(
      otpDigits: state.otpDigits.substring(0, state.otpDigits.length - 1),
      inlineError: null,
    );
  }

  void setNewPassword(String value) {
    if (state.step != ResetPasswordStep.newPassword || state.isSubmitting) {
      return;
    }
    state = state.copyWith(newPassword: value, inlineError: null);
  }

  Future<bool> sendCode() async {
    if (!state.canResendCode) return false;

    final phone = state.phone.trim();
    if (!_isValidPhone(phone)) {
      _setInlineError('请输入正确的 11 位手机号');
      return false;
    }

    state = state.copyWith(isSendingCode: true, inlineError: null);

    final result = await sendResetCodeRequest(phone);
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          isSendingCode: false,
          inlineError: null,
          otpDigits: '',
        );
        _startResendCooldown();
        return true;
      case Failure<void>(error: final error):
        _setInlineError(error.message);
        return false;
    }
  }

  bool submitOtp() {
    if (state.step != ResetPasswordStep.otp) return false;
    if (state.isSubmitting || state.isSendingCode) return false;

    if (state.otpDigits.length != 6) {
      _setInlineError('请输入 6 位验证码');
      return false;
    }

    state = state.copyWith(
      step: ResetPasswordStep.newPassword,
      inlineError: null,
      newPassword: '',
    );
    return true;
  }

  Future<bool> submitNewPassword() async {
    if (state.step != ResetPasswordStep.newPassword || state.isSubmitting) {
      return false;
    }

    final password = state.newPassword;
    if (password.length < 6) {
      _setInlineError('密码至少 6 位');
      return false;
    }
    if (password.length > 20) {
      _setInlineError('密码不能超过 20 位');
      return false;
    }

    state = state.copyWith(isSubmitting: true, inlineError: null);

    final result = await resetPasswordRequest(
      phone: state.phone,
      smsCode: state.otpDigits,
      newPassword: password,
    );

    switch (result) {
      case Success<void>():
        state = state.copyWith(isSubmitting: false, inlineError: null);
        return true;
      case Failure<void>(error: final error):
        if (isOtpInvalidError(error)) {
          state = state.copyWith(
            step: ResetPasswordStep.otp,
            isSubmitting: false,
            otpDigits: '',
            newPassword: '',
            inlineError: '验证码不正确或已过期，请重新输入',
          );
          return false;
        }
        _setInlineError(error.message);
        return false;
    }
  }

  void goBackStep() {
    switch (state.step) {
      case ResetPasswordStep.otp:
        return;
      case ResetPasswordStep.newPassword:
        state = state.copyWith(
          step: ResetPasswordStep.otp,
          newPassword: '',
          inlineError: null,
        );
    }
  }

  void _startResendCooldown() {
    _cancelResendCooldownTimer();
    state = state.copyWith(resendCooldownSeconds: resendCooldownSeconds);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldownSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
        return;
      }
      state = state.copyWith(resendCooldownSeconds: next);
    });
  }

  void _cancelResendCooldownTimer() {
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = null;
  }

  void _setInlineError(String message) {
    state = state.copyWith(
      isSubmitting: false,
      isSendingCode: false,
      inlineError: message,
    );
  }

  bool _isDigit(String value) {
    return value.length == 1 &&
        value.codeUnitAt(0) >= 48 &&
        value.codeUnitAt(0) <= 57;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  @override
  void dispose() {
    _cancelResendCooldownTimer();
    super.dispose();
  }
}
