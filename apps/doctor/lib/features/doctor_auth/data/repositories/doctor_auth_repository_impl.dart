import 'package:app_core/app_core.dart';
import 'package:doctor/core/auth_scope.dart';
import 'package:doctor/features/doctor_auth/data/remote/doctor_auth_api.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';

final class DoctorAuthRepositoryImpl implements DoctorAuthRepository {
  DoctorAuthRepositoryImpl({
    required DoctorAuthApi authApi,
    required SessionStore sessionStore,
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _support = ScopedAuthRepositorySupport(
         authApi: authApi,
         sessionStore: sessionStore,
         scope: doctorAuthScopeConfig,
         executor: executor,
       );

  final ScopedAuthRepositorySupport _support;

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) {
    return _support.sendSmsCode(phone: phone, purpose: purpose);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
  }) {
    return _support.register(
      phone: phone,
      smsCode: smsCode,
      password: password,
    );
  }

  @override
  Future<Result<DoctorLoginCheckResult>> loginCheck({required String phone}) {
    return _support.loginCheck(phone: phone);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) {
    return _support.loginDirect(phone: phone, ticket: ticket);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) {
    return _support.loginPassword(phone: phone, password: password);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> refreshToken() {
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
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _support.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) {
    return _support.logout(refreshToken: refreshToken);
  }
}
