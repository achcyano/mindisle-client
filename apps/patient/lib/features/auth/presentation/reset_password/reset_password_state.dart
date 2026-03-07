import 'package:flutter/foundation.dart';

enum ResetPasswordStep {
  otp,
  newPassword,
}

@immutable
final class ResetPasswordState {
  const ResetPasswordState({
    this.phone = '',
    this.otpDigits = '',
    this.newPassword = '',
    this.step = ResetPasswordStep.otp,
    this.isSubmitting = false,
    this.isSendingCode = false,
    this.resendCooldownSeconds = 0,
    this.inlineError,
  });

  final String phone;
  final String otpDigits;
  final String newPassword;
  final ResetPasswordStep step;
  final bool isSubmitting;
  final bool isSendingCode;
  final int resendCooldownSeconds;
  final String? inlineError;

  bool get canSubmitOtp => otpDigits.length == 6 && !isSubmitting && !isSendingCode;
  bool get canResendCode =>
      resendCooldownSeconds == 0 && !isSubmitting && !isSendingCode;

  ResetPasswordState copyWith({
    String? phone,
    String? otpDigits,
    String? newPassword,
    ResetPasswordStep? step,
    bool? isSubmitting,
    bool? isSendingCode,
    int? resendCooldownSeconds,
    Object? inlineError = _sentinel,
  }) {
    return ResetPasswordState(
      phone: phone ?? this.phone,
      otpDigits: otpDigits ?? this.otpDigits,
      newPassword: newPassword ?? this.newPassword,
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      resendCooldownSeconds: resendCooldownSeconds ?? this.resendCooldownSeconds,
      inlineError:
          identical(inlineError, _sentinel) ? this.inlineError : inlineError as String?,
    );
  }

  static const _sentinel = Object();
}
