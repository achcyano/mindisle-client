import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/auth/presentation/reset_password/reset_password_controller.dart';
import 'package:mindisle_client/features/auth/presentation/reset_password/reset_password_state.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/login_submit_button.dart';
import 'package:mindisle_client/view/widget/number_keypad.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    required this.phone,
    super.key,
  });

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
      ref.read(resetPasswordControllerProvider.notifier).initialize(
            phone: widget.phone,
          );
      unawaited(_sendCode(showSuccessMessage: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final controller = ref.read(resetPasswordControllerProvider.notifier);

    return PopScope<void>(
      canPop: state.step == ResetPasswordStep.otp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.goBackStep();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('修改密码')),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.14, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: switch (state.step) {
              ResetPasswordStep.otp => _ResetOtpStepView(
                  key: const ValueKey('reset_password_step_otp'),
                  phoneDigits: state.phone,
                  otpDigits: state.otpDigits,
                  inlineError: state.inlineError,
                  isSubmitting: state.isSubmitting,
                  isSendingCode: state.isSendingCode,
                  resendCooldownSeconds: state.resendCooldownSeconds,
                  onDigitPressed: controller.inputOtpDigit,
                  onBackspacePressed: controller.deleteOtpDigit,
                  onSubmit: _submitOtp,
                  onResendPressed: () => _sendCode(showSuccessMessage: true),
                ),
              ResetPasswordStep.newPassword => _ResetNewPasswordStepView(
                  key: const ValueKey('reset_password_step_new_password'),
                  phoneDigits: state.phone,
                  inlineError: state.inlineError,
                  isSubmitting: state.isSubmitting,
                  onPasswordChanged: controller.setNewPassword,
                  onSubmit: _submitNewPassword,
                ),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode({required bool showSuccessMessage}) async {
    final controller = ref.read(resetPasswordControllerProvider.notifier);
    final ok = await controller.sendCode();
    if (!mounted) return;

    if (ok) {
      if (showSuccessMessage) {
        _showSnack('验证码已发送');
      }
      return;
    }

    final error = ref.read(resetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      _showSnack(error);
    }
  }

  void _submitOtp() {
    final ok = ref.read(resetPasswordControllerProvider.notifier).submitOtp();
    if (ok) return;
    final error = ref.read(resetPasswordControllerProvider).inlineError;
    if (error != null && error.isNotEmpty) {
      _showSnack(error);
    }
  }

  Future<void> _submitNewPassword() async {
    final controller = ref.read(resetPasswordControllerProvider.notifier);
    final ok = await controller.submitNewPassword();
    if (!mounted) return;

    if (!ok) {
      final error = ref.read(resetPasswordControllerProvider).inlineError;
      if (error != null && error.isNotEmpty) {
        _showSnack(error);
      }
      return;
    }

    await ref.read(sessionStoreProvider).clearSession();
    if (!mounted) return;

    _showSnack('密码修改成功，请重新登录');
    await LoginPage.route.replaceRoot(context);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final mediaQuery = MediaQuery.maybeOf(context);
    final safeBottom = mediaQuery?.padding.bottom ?? 0;
    final viewInsetsBottom = mediaQuery?.viewInsets.bottom ?? 0;
    final step = ref.read(resetPasswordControllerProvider).step;
    final useCustomKeypad = step == ResetPasswordStep.otp;
    final bottomMargin = useCustomKeypad
        ? 236 + safeBottom
        : 16 + safeBottom + viewInsetsBottom;

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        content: Text(message),
      ),
    );
  }
}

class _ResetOtpStepView extends StatefulWidget {
  const _ResetOtpStepView({
    required this.phoneDigits,
    required this.otpDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.isSendingCode,
    required this.resendCooldownSeconds,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    required this.onResendPressed,
    super.key,
  });

  final String phoneDigits;
  final String otpDigits;
  final String? inlineError;
  final bool isSubmitting;
  final bool isSendingCode;
  final int resendCooldownSeconds;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;
  final VoidCallback onResendPressed;

  @override
  State<_ResetOtpStepView> createState() => _ResetOtpStepViewState();
}

class _ResetOtpStepViewState extends State<_ResetOtpStepView> {
  @override
  void didUpdateWidget(covariant _ResetOtpStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justCompleted =
        oldWidget.otpDigits.length < 6 && widget.otpDigits.length == 6;
    if (justCompleted && !widget.isSubmitting && !widget.isSendingCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSubmit();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final descriptionStyle = Theme.of(context).textTheme.bodySmall;
    final canResend =
        widget.resendCooldownSeconds == 0 &&
        !widget.isSubmitting &&
        !widget.isSendingCode;

    return Column(
      children: [
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                '输入验证码',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '验证码已发送至 ${_formatPhone(widget.phoneDigits)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    _OtpCell(
                      value: i < widget.otpDigits.length ? widget.otpDigits[i] : '',
                    ),
                    if (i != 5) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(textStyle: descriptionStyle),
                    onPressed: canResend ? widget.onResendPressed : null,
                    child: Text(
                      canResend
                          ? '重发验证码'
                          : '重发验证码 (${widget.resendCooldownSeconds}s)',
                      style: descriptionStyle,
                    ),
                  ),
                  if (widget.isSendingCode)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.inlineError ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerRight,
            child: LoginSubmitButton(
              isSubmitting: widget.isSubmitting || widget.isSendingCode,
              onPressed: widget.onSubmit,
            ),
          ),
        ),
        const SizedBox(height: 10),
        NumberKeypad(
          onDigitPressed: widget.onDigitPressed,
          onBackspacePressed: widget.onBackspacePressed,
          enabled: !widget.isSubmitting && !widget.isSendingCode,
        ),
      ],
    );
  }

  String _formatPhone(String value) {
    if (value.length != 11) return value;
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}

class _ResetNewPasswordStepView extends StatelessWidget {
  const _ResetNewPasswordStepView({
    required this.phoneDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onPasswordChanged,
    required this.onSubmit,
    super.key,
  });

  final String phoneDigits;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 1.2,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 1.2,
      ),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const Spacer(flex: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  '设置新密码',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '请为 ${_formatPhone(phoneDigits)} 设置新密码（6 到 20 位）',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: TextField(
                    autofocus: true,
                    obscureText: true,
                    enabled: !isSubmitting,
                    onChanged: onPasswordChanged,
                    onSubmitted: (_) => onSubmit(),
                    maxLength: 20,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '请输入新密码',
                      counterText: '',
                      filled: false,
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      disabledBorder: border,
                      errorBorder: errorBorder,
                      focusedErrorBorder: errorBorder,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 18,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      inlineError ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: LoginSubmitButton(
                isSubmitting: isSubmitting,
                onPressed: onSubmit,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatPhone(String value) {
    if (value.length != 11) return value;
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary,
          width: 1.2,
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
