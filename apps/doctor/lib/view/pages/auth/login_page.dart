import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_auth/presentation/login/doctor_login_flow_controller.dart';
import 'package:doctor/features/doctor_auth/presentation/login/doctor_login_flow_state.dart';
import 'package:doctor/view/pages/auth/reset_password_page.dart';
import 'package:doctor/view/pages/doctor_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorLoginPage extends ConsumerWidget {
  const DoctorLoginPage({super.key});

  static final route = AppRoute<void>(
    path: '/login',
    builder: (_) => const DoctorLoginPage(),
    middlewares: [(context, route) => !route.alreadyIn],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorLoginFlowControllerProvider);
    final controller = ref.read(doctorLoginFlowControllerProvider.notifier);

    return AuthLoginFlowPage(
      state: state,
      onBack: controller.goBackStep,
      onPhoneDigitPressed: controller.inputPhoneDigit,
      onPhoneBackspacePressed: controller.deletePhoneDigit,
      onSubmitPhone: () => _submitPhone(context, ref),
      onOtpDigitPressed: controller.inputOtpDigit,
      onOtpBackspacePressed: controller.deleteOtpDigit,
      onSubmitOtp: () => _submitOtp(context, ref),
      onResendCode: () => _sendRegisterCode(context, ref),
      onPasswordChanged: controller.setPassword,
      onSubmitPassword: () => _submitPassword(context, ref),
      onForgotPassword:
          state.mode == DoctorLoginFlowMode.passwordLogin &&
              state.phoneDigits.length == 11
          ? () => DoctorResetPasswordPage.route.go(context, state.phoneDigits)
          : null,
    );
  }

  Future<void> _submitPhone(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(doctorLoginFlowControllerProvider.notifier)
        .submitPhone();
    if (!context.mounted) return;

    switch (result) {
      case DoctorPhoneSubmitResult.authenticated:
        await DoctorShell.route.replaceRoot(context);
        return;
      case DoctorPhoneSubmitResult.codeSent:
        showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
        return;
      case DoctorPhoneSubmitResult.failed:
        _showInlineError(context, ref, useCustomKeypad: true);
        return;
      case DoctorPhoneSubmitResult.movedToPassword:
        return;
    }
  }

  Future<void> _sendRegisterCode(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(doctorLoginFlowControllerProvider.notifier)
        .sendRegisterCode();
    if (!context.mounted) return;

    if (ok) {
      showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
      return;
    }
    _showInlineError(context, ref, useCustomKeypad: true);
  }

  void _submitOtp(BuildContext context, WidgetRef ref) {
    final ok = ref.read(doctorLoginFlowControllerProvider.notifier).submitOtp();
    if (ok) return;
    _showInlineError(context, ref, useCustomKeypad: true);
  }

  Future<void> _submitPassword(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(doctorLoginFlowControllerProvider.notifier)
        .submitPassword();
    if (!context.mounted) return;

    if (!success) {
      _showInlineError(context, ref, useCustomKeypad: false);
      return;
    }
    await DoctorShell.route.replaceRoot(context);
  }

  void _showInlineError(
    BuildContext context,
    WidgetRef ref, {
    required bool useCustomKeypad,
  }) {
    final message = ref.read(doctorLoginFlowControllerProvider).inlineError;
    if (message == null || message.isEmpty) return;
    showAuthSnackBar(context, message, useCustomKeypad: useCustomKeypad);
  }
}
