import 'package:flutter/foundation.dart';

enum LoginStep {
  phone,
  otp,
  password,
}

enum LoginFlowMode {
  undecided,
  passwordLogin,
  register,
}

@immutable
final class LoginFlowState {
  const LoginFlowState({
    this.step = LoginStep.phone,
    this.mode = LoginFlowMode.undecided,
    this.phoneDigits = '',
    this.otpDigits = '',
    this.password = '',
    this.isSubmitting = false,
    this.inlineError,
  });

  final LoginStep step;
  final LoginFlowMode mode;
  final String phoneDigits;
  final String otpDigits;
  final String password;
  final bool isSubmitting;
  final String? inlineError;

  bool get canSubmitPhone => phoneDigits.length == 11 && !isSubmitting;
  bool get canSubmitOtp => otpDigits.length == 6 && !isSubmitting;
  bool get canSubmitPassword => password.length >= 6 && !isSubmitting;

  LoginFlowState copyWith({
    LoginStep? step,
    LoginFlowMode? mode,
    String? phoneDigits,
    String? otpDigits,
    String? password,
    bool? isSubmitting,
    Object? inlineError = _sentinel,
  }) {
    return LoginFlowState(
      step: step ?? this.step,
      mode: mode ?? this.mode,
      phoneDigits: phoneDigits ?? this.phoneDigits,
      otpDigits: otpDigits ?? this.otpDigits,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      inlineError:
          identical(inlineError, _sentinel) ? this.inlineError : inlineError as String?,
    );
  }

  static const _sentinel = Object();
}
