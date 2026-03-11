import 'package:app_core/app_core.dart';
import 'package:patient/core/auth_scope.dart';
import 'package:patient/data/preference/const.dart';
import 'package:patient/features/auth/data/remote/auth_api.dart';
import 'package:patient/features/auth/domain/entities/auth_entities.dart';
import 'package:patient/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required SessionStore sessionStore,
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _support = ScopedAuthRepositorySupport(
         authApi: authApi,
         sessionStore: sessionStore,
         scope: patientAuthScopeConfig,
         executor: executor,
         onSessionSaved: (_) => AppPrefs.hasCompletedFirstLogin.set(true),
       );

  final ScopedAuthRepositorySupport _support;

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  }) {
    final headers = forwardedFor == null || forwardedFor.isEmpty
        ? null
        : <String, String>{'X-Forwarded-For': forwardedFor};
    return _support.sendSmsCode(
      phone: phone,
      purpose: purpose,
      headers: headers,
    );
  }

  @override
  Future<Result<AuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) {
    return _support.register(
      phone: phone,
      smsCode: smsCode,
      password: password,
      profile: profile,
    );
  }

  @override
  Future<Result<LoginCheckResult>> loginCheck({required String phone}) {
    return _support.loginCheck(phone: phone);
  }

  @override
  Future<Result<AuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) {
    return _support.loginDirect(phone: phone, ticket: ticket);
  }

  @override
  Future<Result<AuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) {
    return _support.loginPassword(phone: phone, password: password);
  }

  @override
  Future<Result<AuthSessionResult>> refreshToken() {
    return _support.refreshToken();
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) {
    return _support.resetPassword(
      phone: phone,
      smsCode: smsCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) {
    return _support.logout(refreshToken: refreshToken);
  }
}
