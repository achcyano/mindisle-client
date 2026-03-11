import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/features/auth/presentation/login/login_flow_controller.dart';
import 'package:patient/features/auth/presentation/login/login_flow_state.dart';
import 'package:patient/view/pages/home_shell.dart';
import 'package:patient/view/pages/info/info_page.dart';
import 'package:patient/view/pages/login/reset_password_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static final route = AppRoute<void>(
    path: '/login',
    builder: (_) => const LoginPage(),
    middlewares: [(context, route) => !route.alreadyIn],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginFlowControllerProvider);
    final controller = ref.read(loginFlowControllerProvider.notifier);

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
          state.mode == LoginFlowMode.passwordLogin &&
              state.phoneDigits.length == 11
          ? () => ResetPasswordPage.route.go(context, state.phoneDigits)
          : null,
    );
  }

  Future<void> _submitPhone(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(loginFlowControllerProvider.notifier)
        .submitPhone();
    if (!context.mounted) return;

    switch (result) {
      case AuthPhoneSubmitResult.authenticated:
        await HomeShell.route.replace(context);
        return;
      case AuthPhoneSubmitResult.codeSent:
        showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
        return;
      case AuthPhoneSubmitResult.failed:
        _showInlineError(context, ref, useCustomKeypad: true);
        return;
      case AuthPhoneSubmitResult.movedToPassword:
        return;
    }
  }

  Future<void> _sendRegisterCode(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(loginFlowControllerProvider.notifier)
        .sendRegisterCode();
    if (!context.mounted) return;

    if (ok) {
      showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
      return;
    }
    _showInlineError(context, ref, useCustomKeypad: true);
  }

  void _submitOtp(BuildContext context, WidgetRef ref) {
    final ok = ref.read(loginFlowControllerProvider.notifier).submitOtp();
    if (ok) return;
    _showInlineError(context, ref, useCustomKeypad: true);
  }

  Future<void> _submitPassword(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(loginFlowControllerProvider).mode;
    final success = await ref
        .read(loginFlowControllerProvider.notifier)
        .submitPassword();
    if (!context.mounted) return;

    if (!success) {
      _showInlineError(context, ref, useCustomKeypad: false);
      return;
    }

    if (mode == LoginFlowMode.register) {
      await InfoPage.requiredRoute.replaceRoot(context);
      return;
    }
    await HomeShell.route.replace(context);
  }

  void _showInlineError(
    BuildContext context,
    WidgetRef ref, {
    required bool useCustomKeypad,
  }) {
    final message = ref.read(loginFlowControllerProvider).inlineError;
    if (message == null || message.isEmpty) return;
    showAuthSnackBar(context, message, useCustomKeypad: useCustomKeypad);
  }
}
