import 'dart:async';

import 'package:app_ui/src/widget/auth/auth_otp_step_view.dart';
import 'package:app_ui/src/widget/auth/auth_password_step_view.dart';
import 'package:app_ui/src/widget/auth/auth_phone_step_view.dart';
import 'package:app_ui/src/widget/auth/auth_step_switcher.dart';
import 'package:app_ui/src/widget/auth/auth_utils.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class AuthLoginFlowPage extends StatelessWidget {
  const AuthLoginFlowPage({
    required this.state,
    required this.onBack,
    required this.onPhoneDigitPressed,
    required this.onPhoneBackspacePressed,
    required this.onSubmitPhone,
    required this.onOtpDigitPressed,
    required this.onOtpBackspacePressed,
    required this.onSubmitOtp,
    required this.onPasswordChanged,
    required this.onSubmitPassword,
    super.key,
    this.onResendCode,
    this.onForgotPassword,
  });

  final LoginFlowState state;
  final VoidCallback onBack;
  final ValueChanged<String> onPhoneDigitPressed;
  final VoidCallback onPhoneBackspacePressed;
  final FutureOr<void> Function() onSubmitPhone;
  final ValueChanged<String> onOtpDigitPressed;
  final VoidCallback onOtpBackspacePressed;
  final VoidCallback onSubmitOtp;
  final FutureOr<void> Function()? onResendCode;
  final ValueChanged<String> onPasswordChanged;
  final FutureOr<void> Function() onSubmitPassword;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: state.step == LoginStep.phone,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: AuthStepSwitcher(
            beginOffset: const Offset(0.18, 0),
            child: switch (state.step) {
              LoginStep.phone => AuthPhoneStepView(
                key: const ValueKey('auth_login_step_phone'),
                phoneDigits: state.phoneDigits,
                inlineError: state.inlineError,
                isSubmitting: state.isSubmitting || state.isSendingCode,
                onDigitPressed: onPhoneDigitPressed,
                onBackspacePressed: onPhoneBackspacePressed,
                onSubmit: () => unawaited(Future<void>.sync(onSubmitPhone)),
              ),
              LoginStep.otp => AuthOtpStepView(
                key: const ValueKey('auth_login_step_otp'),
                phoneDigits: state.phoneDigits,
                otpDigits: state.otpDigits,
                inlineError: state.inlineError,
                isSubmitting: state.isSubmitting,
                isSendingCode: state.isSendingCode,
                resendCooldownSeconds: state.resendCooldownSeconds,
                onDigitPressed: onOtpDigitPressed,
                onBackspacePressed: onOtpBackspacePressed,
                onSubmit: onSubmitOtp,
                onResendPressed: onResendCode == null
                    ? null
                    : () => unawaited(Future<void>.sync(onResendCode!)),
              ),
              LoginStep.password => AuthPasswordStepView(
                key: const ValueKey('auth_login_step_password'),
                title: state.mode == LoginFlowMode.register
                    ? '设置登录密码'
                    : '输入登录密码',
                description: state.mode == LoginFlowMode.register
                    ? '为 ${formatAuthPhone(state.phoneDigits)} 设置密码（6 到 20 位）'
                    : '请输入 ${formatAuthPhone(state.phoneDigits)} 的密码',
                labelText: '密码',
                hintText: '请输入密码',
                inlineError: state.inlineError,
                isSubmitting: state.isSubmitting,
                onPasswordChanged: onPasswordChanged,
                onSubmit: () => unawaited(Future<void>.sync(onSubmitPassword)),
                onForgotPassword: onForgotPassword,
              ),
            },
          ),
        ),
      ),
    );
  }
}
