import 'dart:async';

import 'package:app_ui/src/widget/auth/auth_otp_step_view.dart';
import 'package:app_ui/src/widget/auth/auth_password_step_view.dart';
import 'package:app_ui/src/widget/auth/auth_step_switcher.dart';
import 'package:app_ui/src/widget/auth/auth_utils.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class AuthResetPasswordFlowPage extends StatelessWidget {
  const AuthResetPasswordFlowPage({
    required this.state,
    required this.onBack,
    required this.onOtpDigitPressed,
    required this.onOtpBackspacePressed,
    required this.onSubmitOtp,
    required this.onSendCode,
    required this.onPasswordChanged,
    required this.onSubmitNewPassword,
    super.key,
    this.title = '重置密码',
  });

  final ResetPasswordState state;
  final VoidCallback onBack;
  final ValueChanged<String> onOtpDigitPressed;
  final VoidCallback onOtpBackspacePressed;
  final VoidCallback onSubmitOtp;
  final FutureOr<void> Function() onSendCode;
  final ValueChanged<String> onPasswordChanged;
  final FutureOr<void> Function() onSubmitNewPassword;
  final String title;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: state.step == ResetPasswordStep.otp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: AuthStepSwitcher(
            duration: const Duration(milliseconds: 260),
            beginOffset: const Offset(0.14, 0),
            child: switch (state.step) {
              ResetPasswordStep.otp => AuthOtpStepView(
                key: const ValueKey('auth_reset_password_step_otp'),
                phoneDigits: state.phone,
                otpDigits: state.otpDigits,
                inlineError: state.inlineError,
                isSubmitting: state.isSubmitting,
                isSendingCode: state.isSendingCode,
                resendCooldownSeconds: state.resendCooldownSeconds,
                onDigitPressed: onOtpDigitPressed,
                onBackspacePressed: onOtpBackspacePressed,
                onSubmit: onSubmitOtp,
                onResendPressed: () => unawaited(Future<void>.sync(onSendCode)),
                showSubmitButton: true,
              ),
              ResetPasswordStep.newPassword => AuthPasswordStepView(
                key: const ValueKey('auth_reset_password_step_new_password'),
                title: '设置新密码',
                description:
                    '请为 ${formatAuthPhone(state.phone)} 设置新密码（6 到 20 位）',
                labelText: '新密码',
                hintText: '请输入新密码',
                inlineError: state.inlineError,
                isSubmitting: state.isSubmitting,
                onPasswordChanged: onPasswordChanged,
                onSubmit: () =>
                    unawaited(Future<void>.sync(onSubmitNewPassword)),
              ),
            },
          ),
        ),
      ),
    );
  }
}
