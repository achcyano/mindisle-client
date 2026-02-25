import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';
import 'package:mindisle_client/features/auth/presentation/login/login_flow_state.dart';
import 'package:mindisle_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';
import 'package:mindisle_client/view/pages/home_shell.dart';
import 'package:mindisle_client/view/route/app_navigator.dart';

final loginFlowControllerProvider = StateNotifierProvider.autoDispose<
    LoginFlowController, LoginFlowState>((ref) {
  return LoginFlowController(ref);
});

final class LoginFlowController extends StateNotifier<LoginFlowState> {
  LoginFlowController(this._ref) : super(const LoginFlowState());

  final Ref _ref;

  void inputPhoneDigit(String digit) {
    if (state.step != LoginStep.phone || state.isSubmitting) return;
    if (!_isDigit(digit) || state.phoneDigits.length >= 11) return;

    state = state.copyWith(
      phoneDigits: state.phoneDigits + digit,
      inlineError: null,
    );
  }

  void deletePhoneDigit() {
    if (state.step != LoginStep.phone || state.isSubmitting) return;
    if (state.phoneDigits.isEmpty) return;

    state = state.copyWith(
      phoneDigits: state.phoneDigits.substring(0, state.phoneDigits.length - 1),
      inlineError: null,
    );
  }

  void inputOtpDigit(String digit) {
    if (state.step != LoginStep.otp || state.isSubmitting) return;
    if (!_isDigit(digit) || state.otpDigits.length >= 6) return;

    state = state.copyWith(
      otpDigits: state.otpDigits + digit,
      inlineError: null,
    );
  }

  void deleteOtpDigit() {
    if (state.step != LoginStep.otp || state.isSubmitting) return;
    if (state.otpDigits.isEmpty) return;

    state = state.copyWith(
      otpDigits: state.otpDigits.substring(0, state.otpDigits.length - 1),
      inlineError: null,
    );
  }

  void setPassword(String value) {
    if (state.step != LoginStep.password || state.isSubmitting) return;
    state = state.copyWith(password: value, inlineError: null);
  }

  Future<void> submitPhone(BuildContext context) async {
    if (state.isSubmitting) return;

    final phone = state.phoneDigits;
    if (!_isValidPhone(phone)) {
      _setInlineError('请输入正确的 11 位手机号');
      return;
    }

    state = state.copyWith(isSubmitting: true, inlineError: null);

    final checkResult = await _ref.read(loginCheckUseCaseProvider).execute(phone);
    switch (checkResult) {
      case Failure(error: final error):
        _fail(error.message);
        return;
      case Success(data: final data):
        if (!context.mounted) return;
        await _handleLoginDecision(context, phone: phone, result: data);
    }
  }

  Future<void> submitOtp() async {
    if (state.isSubmitting) return;

    if (state.mode != LoginFlowMode.register) {
      _fail('当前流程不支持验证码登录');
      return;
    }

    if (state.otpDigits.length != 6) {
      _setInlineError('请输入 6 位验证码');
      return;
    }

    state = state.copyWith(isSubmitting: true, inlineError: null);
    await Future<void>.delayed(const Duration(milliseconds: 220));

    state = state.copyWith(
      step: LoginStep.password,
      isSubmitting: false,
      inlineError: null,
      password: '',
    );
    _showSnackBar('请设置登录密码');
  }

  Future<void> submitPassword(BuildContext context) async {
    if (state.isSubmitting) return;

    if (state.password.length < 6) {
      _setInlineError('密码至少 6 位');
      return;
    }
    if (state.password.length > 20) {
      _setInlineError('密码不能超过 20 位');
      return;
    }

    state = state.copyWith(isSubmitting: true, inlineError: null);

    switch (state.mode) {
      case LoginFlowMode.passwordLogin:
        await _loginWithPassword(context);
        return;
      case LoginFlowMode.register:
        await _registerAccount(context);
        return;
      case LoginFlowMode.undecided:
        _fail('请先完成手机号校验');
        return;
    }
  }

  void goBackStep() {
    switch (state.step) {
      case LoginStep.phone:
        return;
      case LoginStep.otp:
        state = state.copyWith(
          step: LoginStep.phone,
          mode: LoginFlowMode.undecided,
          otpDigits: '',
          password: '',
          isSubmitting: false,
          inlineError: null,
        );
        return;
      case LoginStep.password:
        if (state.mode == LoginFlowMode.register) {
          state = state.copyWith(
            step: LoginStep.otp,
            password: '',
            isSubmitting: false,
            inlineError: null,
          );
          return;
        }

        state = state.copyWith(
          step: LoginStep.phone,
          mode: LoginFlowMode.undecided,
          otpDigits: '',
          password: '',
          isSubmitting: false,
          inlineError: null,
        );
    }
  }

  Future<void> _handleLoginDecision(
    BuildContext context, {
    required String phone,
    required LoginCheckResult result,
  }) async {
    switch (result.decision) {
      case AuthLoginDecision.directLoginAllowed:
        final ticket = result.ticket;
        if (ticket == null || ticket.isEmpty) {
          _fail('登录票据无效，请重试');
          return;
        }
        await _directLogin(context, phone: phone, ticket: ticket);
        return;
      case AuthLoginDecision.passwordRequired:
        state = state.copyWith(
          step: LoginStep.password,
          mode: LoginFlowMode.passwordLogin,
          isSubmitting: false,
          inlineError: null,
          password: '',
          otpDigits: '',
        );
        return;
      case AuthLoginDecision.registerRequired:
        final sendCodeResult = await _ref.read(sendSmsCodeUseCaseProvider).execute(
              phone: phone,
              purpose: SmsPurpose.register,
            );

        switch (sendCodeResult) {
          case Failure(error: final error):
            _fail(error.message);
            return;
          case Success():
            state = state.copyWith(
              step: LoginStep.otp,
              mode: LoginFlowMode.register,
              isSubmitting: false,
              inlineError: null,
              otpDigits: '',
            );
            _showSnackBar('验证码已发送');
            return;
        }
    }
  }

  Future<void> _directLogin(
    BuildContext context, {
    required String phone,
    required String ticket,
  }) async {
    final result = await _ref.read(loginDirectUseCaseProvider).execute(
          phone: phone,
          ticket: ticket,
        );

    switch (result) {
      case Failure(error: final error):
        _fail(error.message);
        return;
      case Success():
        await _warmUpAvatarCache();
        _refreshProfileInBackground();
        state = state.copyWith(isSubmitting: false, inlineError: null);
        if (!context.mounted) return;
        await HomeShell.route.replace(context);
        return;
    }
  }

  Future<void> _loginWithPassword(BuildContext context) async {
    final result = await _ref.read(loginPasswordUseCaseProvider).execute(
          phone: state.phoneDigits,
          password: state.password,
        );

    switch (result) {
      case Failure(error: final error):
        _fail(error.message);
        return;
      case Success():
        await _warmUpAvatarCache();
        _refreshProfileInBackground();
        state = state.copyWith(isSubmitting: false, inlineError: null);
        if (!context.mounted) return;
        await HomeShell.route.replace(context);
        return;
    }
  }

  Future<void> _registerAccount(BuildContext context) async {
    final result = await _ref.read(registerUseCaseProvider).execute(
          phone: state.phoneDigits,
          smsCode: state.otpDigits,
          password: state.password,
        );

    switch (result) {
      case Failure(error: final error):
        final code = error.code;
        if (code == 40003 ||
            code == 42903 ||
            (code == 50010 && error.message.contains('验证码'))) {
          state = state.copyWith(
            step: LoginStep.otp,
            isSubmitting: false,
            password: '',
            otpDigits: '',
            inlineError: '验证码不正确或已过期，请重新输入',
          );
          _showSnackBar('验证码不正确或已过期');
          return;
        }
        _fail(error.message);
        return;
      case Success():
        await _warmUpAvatarCache();
        _refreshProfileInBackground();
        state = state.copyWith(isSubmitting: false, inlineError: null);
        if (!context.mounted) return;
        await HomeShell.route.replace(context);
        return;
    }
  }

  void _setInlineError(String message) {
    state = state.copyWith(inlineError: message);
  }

  void _fail(String message) {
    state = state.copyWith(isSubmitting: false, inlineError: message);
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    final messenger = AppNavigator.scaffoldMessengerKey.currentState;
    final context = AppNavigator.key.currentContext;
    final mediaQuery = context != null ? MediaQuery.of(context) : null;
    final safeBottom = mediaQuery?.padding.bottom ?? 0;
    final viewInsetsBottom = mediaQuery?.viewInsets.bottom ?? 0;

    final useCustomKeypad =
        state.step == LoginStep.phone || state.step == LoginStep.otp;
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

  Future<void> _warmUpAvatarCache() async {
    try {
      await _ref
          .read(avatarWarmupServiceProvider)
          .warmUp()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Ignore warm-up failures to avoid blocking login flow.
    }
  }

  void _refreshProfileInBackground() {
    unawaited(_ref.read(getBasicProfileUseCaseProvider).execute());
  }

  bool _isDigit(String value) {
    return value.length == 1 && value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }
}

