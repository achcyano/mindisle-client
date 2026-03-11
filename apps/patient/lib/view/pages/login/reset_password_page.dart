import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/features/auth/presentation/reset_password/reset_password_controller.dart';
import 'package:patient/view/pages/login/login_page.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({required this.phone, super.key});

  final String phone;

  static final route = AppRouteArg<void, String>(
    path: '/password/reset',
    builder: (phone) => ResetPasswordPage(phone: phone),
  );

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(resetPasswordControllerProvider.notifier)
          .initialize(phone: widget.phone);
      unawaited(_sendCode(showSuccessMessage: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final controller = ref.read(resetPasswordControllerProvider.notifier);

    return AuthResetPasswordFlowPage(
      state: state,
      onBack: controller.goBackStep,
      onOtpDigitPressed: controller.inputOtpDigit,
      onOtpBackspacePressed: controller.deleteOtpDigit,
      onSubmitOtp: _submitOtp,
      onSendCode: () => _sendCode(showSuccessMessage: true),
      onPasswordChanged: controller.setNewPassword,
      onSubmitNewPassword: _submitNewPassword,
    );
  }

  Future<void> _sendCode({required bool showSuccessMessage}) async {
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .sendCode();
    if (!mounted) return;

    if (ok) {
      if (showSuccessMessage) {
        showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
      }
      return;
    }

    final error = ref.read(resetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      showAuthSnackBar(context, error, useCustomKeypad: true);
    }
  }

  void _submitOtp() {
    final ok = ref.read(resetPasswordControllerProvider.notifier).submitOtp();
    if (ok) return;

    final error = ref.read(resetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      showAuthSnackBar(context, error, useCustomKeypad: true);
    }
  }

  Future<void> _submitNewPassword() async {
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submitNewPassword();
    if (!mounted) return;

    if (!ok) {
      final error = ref.read(resetPasswordControllerProvider).inlineError;
      if (error != null && error.isNotEmpty) {
        showAuthSnackBar(context, error, useCustomKeypad: false);
      }
      return;
    }

    await ref.read(sessionStoreProvider).clearSession();
    if (!mounted) return;

    showAuthSnackBar(context, '密码修改成功，请重新登录', useCustomKeypad: false);
    await LoginPage.route.replaceRoot(context);
  }
}
