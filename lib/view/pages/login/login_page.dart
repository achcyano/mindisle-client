import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/auth/presentation/login/login_flow_controller.dart';
import 'package:mindisle_client/features/auth/presentation/login/login_flow_state.dart';
import 'package:mindisle_client/view/pages/login/steps/otp_step_view.dart';
import 'package:mindisle_client/view/pages/login/steps/password_step_view.dart';
import 'package:mindisle_client/view/pages/login/steps/phone_step_view.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static final route = AppRoute<void>(
    path: '/login',
    builder: (_) => const LoginPage(),
    middlewares: [
      (context, route) => !route.alreadyIn,
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginFlowControllerProvider);
    final controller = ref.read(loginFlowControllerProvider.notifier);

    return PopScope<void>(
      canPop: state.step == LoginStep.phone,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.goBackStep();
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.18, 0),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: switch (state.step) {
              LoginStep.phone => PhoneStepView(
                  key: const ValueKey('login_step_phone'),
                  phoneDigits: state.phoneDigits,
                  inlineError: state.inlineError,
                  isSubmitting: state.isSubmitting,
                  onDigitPressed: controller.inputPhoneDigit,
                  onBackspacePressed: controller.deletePhoneDigit,
                  onSubmit: () => controller.submitPhone(context),
                ),
              LoginStep.otp => OtpStepView(
                  key: const ValueKey('login_step_otp'),
                  phoneDigits: state.phoneDigits,
                  otpDigits: state.otpDigits,
                  inlineError: state.inlineError,
                  isSubmitting: state.isSubmitting,
                  onDigitPressed: controller.inputOtpDigit,
                  onBackspacePressed: controller.deleteOtpDigit,
                  onSubmit: () => controller.submitOtp(),
                ),
              LoginStep.password => PasswordStepView(
                  key: const ValueKey('login_step_password'),
                  mode: state.mode,
                  phoneDigits: state.phoneDigits,
                  inlineError: state.inlineError,
                  isSubmitting: state.isSubmitting,
                  onPasswordChanged: controller.setPassword,
                  onSubmit: () => controller.submitPassword(context),
                ),
            },
          ),
        ),
      ),
    );
  }
}
