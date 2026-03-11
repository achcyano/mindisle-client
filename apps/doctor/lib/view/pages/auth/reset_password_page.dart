import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/features/doctor_auth/presentation/reset_password/doctor_reset_password_controller.dart';
import 'package:doctor/view/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorResetPasswordPage extends ConsumerStatefulWidget {
  const DoctorResetPasswordPage({required this.phone, super.key});

  final String phone;

  static final route = AppRouteArg<void, String>(
    path: '/password/reset',
    builder: (phone) => DoctorResetPasswordPage(phone: phone),
  );

  @override
  ConsumerState<DoctorResetPasswordPage> createState() =>
      _DoctorResetPasswordPageState();
}

class _DoctorResetPasswordPageState
    extends ConsumerState<DoctorResetPasswordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(doctorResetPasswordControllerProvider.notifier)
          .initialize(phone: widget.phone);
      unawaited(_sendCode(showSuccessMessage: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorResetPasswordControllerProvider);
    final controller = ref.read(doctorResetPasswordControllerProvider.notifier);

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
        .read(doctorResetPasswordControllerProvider.notifier)
        .sendCode();
    if (!mounted) return;

    if (ok) {
      if (showSuccessMessage) {
        showAuthSnackBar(context, '验证码已发送', useCustomKeypad: true);
      }
      return;
    }

    final error = ref.read(doctorResetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      showAuthSnackBar(context, error, useCustomKeypad: true);
    }
  }

  void _submitOtp() {
    final ok = ref
        .read(doctorResetPasswordControllerProvider.notifier)
        .submitOtp();
    if (ok) return;

    final error = ref.read(doctorResetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      showAuthSnackBar(context, error, useCustomKeypad: true);
    }
  }

  Future<void> _submitNewPassword() async {
    final ok = await ref
        .read(doctorResetPasswordControllerProvider.notifier)
        .submitNewPassword();
    if (!mounted) return;

    if (!ok) {
      final error = ref.read(doctorResetPasswordControllerProvider).inlineError;
      if (error != null && error.isNotEmpty) {
        showAuthSnackBar(context, error, useCustomKeypad: false);
      }
      return;
    }

    await ref.read(sessionStoreProvider).clearSession();
    ref.read(doctorAuthControllerProvider.notifier).clearSession();
    if (!mounted) return;

    showAuthSnackBar(context, '密码修改成功，请重新登录', useCustomKeypad: false);
    await DoctorLoginPage.route.replaceRoot(context);
  }
}
