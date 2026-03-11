import 'dart:async';

import 'package:app_core/src/result/app_error.dart';
import 'package:app_core/src/result/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

abstract class BaseLoginFlowController<SessionT>
    extends StateNotifier<LoginFlowState> {
  BaseLoginFlowController() : super(const LoginFlowState());

  static const int resendCooldownSeconds = 60;

  Timer? _resendCooldownTimer;

  Future<Result<AuthLoginCheckResult>> loginCheck(String phone);

  Future<Result<void>> sendRegisterCodeRequest(String phone);

  Future<Result<SessionT>> loginDirectRequest({
    required String phone,
    required String ticket,
  });

  Future<Result<SessionT>> loginPasswordRequest({
    required String phone,
    required String password,
  });

  Future<Result<SessionT>> registerRequest({
    required String phone,
    required String smsCode,
    required String password,
  });

  Future<void> onAuthSucceeded(SessionT session, LoginFlowMode mode);

  bool isOtpInvalidError(AppError error) {
    return error.code == 40003 ||
        error.code == 42903 ||
        (error.code == 50010 && error.message.contains('验证码'));
  }

  void inputPhoneDigit(String digit) {
    if (state.step != LoginStep.phone ||
        state.isSubmitting ||
        state.isSendingCode) {
      return;
    }
    if (!_isDigit(digit) || state.phoneDigits.length >= 11) return;

    state = state.copyWith(
      phoneDigits: state.phoneDigits + digit,
      inlineError: null,
    );
  }

  void deletePhoneDigit() {
    if (state.step != LoginStep.phone ||
        state.isSubmitting ||
        state.isSendingCode) {
      return;
    }
    if (state.phoneDigits.isEmpty) return;

    state = state.copyWith(
      phoneDigits: state.phoneDigits.substring(0, state.phoneDigits.length - 1),
      inlineError: null,
    );
  }

  void inputOtpDigit(String digit) {
    if (state.step != LoginStep.otp) return;
    if (state.isSubmitting || state.isSendingCode) return;
    if (!_isDigit(digit) || state.otpDigits.length >= 6) return;

    state = state.copyWith(
      otpDigits: state.otpDigits + digit,
      inlineError: null,
    );
  }

  void deleteOtpDigit() {
    if (state.step != LoginStep.otp) return;
    if (state.isSubmitting || state.isSendingCode) return;
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

  Future<AuthPhoneSubmitResult> submitPhone() async {
    if (state.isSubmitting || state.isSendingCode) {
      return AuthPhoneSubmitResult.failed;
    }

    final phone = state.phoneDigits;
    if (!_isValidPhone(phone)) {
      _setInlineError('请输入正确的 11 位手机号');
      return AuthPhoneSubmitResult.failed;
    }

    state = state.copyWith(
      isSubmitting: true,
      isSendingCode: false,
      inlineError: null,
    );

    final checkResult = await loginCheck(phone);
    switch (checkResult) {
      case Failure<AuthLoginCheckResult>(error: final error):
        _fail(error.message);
        return AuthPhoneSubmitResult.failed;
      case Success<AuthLoginCheckResult>(data: final data):
        return _handleLoginDecision(phone: phone, result: data);
    }
  }

  Future<bool> sendRegisterCode({bool bypassAvailabilityCheck = false}) async {
    if (state.step != LoginStep.phone && state.step != LoginStep.otp) {
      return false;
    }
    if (state.isSubmitting || state.isSendingCode) {
      return false;
    }
    if (!bypassAvailabilityCheck && !state.canResendCode) {
      _setInlineError('请稍后再试');
      return false;
    }
    if (!_isValidPhone(state.phoneDigits)) {
      _setInlineError('请输入正确的 11 位手机号');
      return false;
    }

    state = state.copyWith(isSendingCode: true, inlineError: null);

    final result = await sendRegisterCodeRequest(state.phoneDigits);
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          step: LoginStep.otp,
          mode: LoginFlowMode.register,
          isSubmitting: false,
          isSendingCode: false,
          otpDigits: '',
          inlineError: null,
        );
        _startResendCooldown();
        return true;
      case Failure<void>(error: final error):
        _fail(error.message, step: state.step);
        return false;
    }
  }

  bool submitOtp() {
    if (state.step != LoginStep.otp) return false;
    if (state.isSubmitting || state.isSendingCode) return false;

    if (state.mode != LoginFlowMode.register) {
      _fail('当前流程不支持验证码登录', step: LoginStep.otp);
      return false;
    }

    if (state.otpDigits.length != 6) {
      _setInlineError('请输入 6 位验证码');
      return false;
    }

    state = state.copyWith(
      step: LoginStep.password,
      inlineError: null,
      password: '',
    );
    return true;
  }

  Future<bool> submitPassword() async {
    if (state.step != LoginStep.password || state.isSubmitting) {
      return false;
    }

    final password = state.password;
    if (password.length < 6) {
      _setInlineError('密码至少 6 位');
      return false;
    }
    if (password.length > 20) {
      _setInlineError('密码不能超过 20 位');
      return false;
    }

    state = state.copyWith(isSubmitting: true, inlineError: null);

    switch (state.mode) {
      case LoginFlowMode.passwordLogin:
        return _loginWithPassword(password);
      case LoginFlowMode.register:
        return _registerAccount(password);
      case LoginFlowMode.undecided:
        _fail('请先完成手机号校验');
        return false;
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
          isSendingCode: false,
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

  Future<AuthPhoneSubmitResult> _handleLoginDecision({
    required String phone,
    required AuthLoginCheckResult result,
  }) async {
    switch (result.decision) {
      case AuthLoginDecision.directLoginAllowed:
        final ticket = result.ticket;
        if (ticket == null || ticket.isEmpty) {
          _fail('登录票据无效，请重试');
          return AuthPhoneSubmitResult.failed;
        }
        final success = await _directLogin(phone: phone, ticket: ticket);
        return success
            ? AuthPhoneSubmitResult.authenticated
            : AuthPhoneSubmitResult.failed;
      case AuthLoginDecision.passwordRequired:
        state = state.copyWith(
          step: LoginStep.password,
          mode: LoginFlowMode.passwordLogin,
          isSubmitting: false,
          inlineError: null,
          password: '',
          otpDigits: '',
        );
        return AuthPhoneSubmitResult.movedToPassword;
      case AuthLoginDecision.registerRequired:
        state = state.copyWith(isSubmitting: false, inlineError: null);
        final sent = await sendRegisterCode(bypassAvailabilityCheck: true);
        return sent
            ? AuthPhoneSubmitResult.codeSent
            : AuthPhoneSubmitResult.failed;
    }
  }

  Future<bool> _directLogin({
    required String phone,
    required String ticket,
  }) async {
    final result = await loginDirectRequest(phone: phone, ticket: ticket);
    switch (result) {
      case Failure<SessionT>(error: final error):
        _fail(error.message);
        return false;
      case Success<SessionT>(data: final data):
        await onAuthSucceeded(data, LoginFlowMode.undecided);
        state = state.copyWith(isSubmitting: false, inlineError: null);
        return true;
    }
  }

  Future<bool> _loginWithPassword(String password) async {
    final result = await loginPasswordRequest(
      phone: state.phoneDigits,
      password: password,
    );

    switch (result) {
      case Failure<SessionT>(error: final error):
        _fail(error.message, step: LoginStep.password);
        return false;
      case Success<SessionT>(data: final data):
        await onAuthSucceeded(data, LoginFlowMode.passwordLogin);
        state = state.copyWith(isSubmitting: false, inlineError: null);
        return true;
    }
  }

  Future<bool> _registerAccount(String password) async {
    if (state.otpDigits.length != 6) {
      state = state.copyWith(
        step: LoginStep.otp,
        isSubmitting: false,
        password: '',
      );
      _setInlineError('验证码无效，请重新输入');
      return false;
    }

    final result = await registerRequest(
      phone: state.phoneDigits,
      smsCode: state.otpDigits,
      password: password,
    );

    switch (result) {
      case Success<SessionT>(data: final data):
        await onAuthSucceeded(data, LoginFlowMode.register);
        state = state.copyWith(isSubmitting: false, inlineError: null);
        return true;
      case Failure<SessionT>(error: final error):
        if (isOtpInvalidError(error)) {
          state = state.copyWith(
            step: LoginStep.otp,
            isSubmitting: false,
            otpDigits: '',
            password: '',
            inlineError: '验证码不正确或已过期，请重新输入',
          );
          return false;
        }
        _fail(error.message, step: LoginStep.password);
        return false;
    }
  }

  void _startResendCooldown() {
    _cancelResendCooldownTimer();
    state = state.copyWith(resendCooldownSeconds: resendCooldownSeconds);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldownSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
        return;
      }
      state = state.copyWith(resendCooldownSeconds: next);
    });
  }

  void _cancelResendCooldownTimer() {
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = null;
  }

  void _setInlineError(String message) {
    state = state.copyWith(
      isSubmitting: false,
      isSendingCode: false,
      inlineError: message,
    );
  }

  void _fail(String message, {LoginStep? step}) {
    state = state.copyWith(
      step: step,
      isSubmitting: false,
      isSendingCode: false,
      inlineError: message,
    );
  }

  bool _isDigit(String value) {
    return value.length == 1 &&
        value.codeUnitAt(0) >= 48 &&
        value.codeUnitAt(0) <= 57;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  @override
  void dispose() {
    _cancelResendCooldownTimer();
    super.dispose();
  }
}
