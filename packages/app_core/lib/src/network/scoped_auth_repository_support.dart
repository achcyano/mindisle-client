import 'package:app_core/src/network/api_call_executor.dart';
import 'package:app_core/src/network/auth_scope_config.dart';
import 'package:app_core/src/network/error_mapper.dart';
import 'package:app_core/src/network/scoped_auth_api_client.dart';
import 'package:app_core/src/result/result.dart';
import 'package:app_core/src/session/session_store.dart';
import 'package:models/models.dart';

typedef AuthSessionSavedHook =
    Future<void> Function(PrincipalAuthSessionResult session);

final class ScopedAuthRepositorySupport {
  ScopedAuthRepositorySupport({
    required ScopedAuthApiClient authApi,
    required SessionStore sessionStore,
    required AuthScopeConfig scope,
    this.onSessionSaved,
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _authApi = authApi,
       _sessionStore = sessionStore,
       _scope = scope,
       _executor = executor;

  final ScopedAuthApiClient _authApi;
  final SessionStore _sessionStore;
  final AuthScopeConfig _scope;
  final AuthSessionSavedHook? onSessionSaved;
  final ApiCallExecutor _executor;

  Future<Result<void>> sendSmsCode({
    required String phone,
    required AuthSmsPurpose purpose,
    Map<String, String>? headers,
  }) async {
    final result = await _executor.runNoData(
      () => _authApi.sendSmsCode(
        SendSmsCodePayload(phone: phone, purpose: purpose),
        headers: headers,
      ),
    );
    return _toVoidResult(result);
  }

  Future<Result<PrincipalAuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) async {
    final result = await _executor.run(
      () => _authApi.register(
        RegisterPayload(
          phone: phone,
          smsCode: smsCode,
          password: password,
          profile: profile,
        ),
      ),
      (raw) => AuthSessionResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
        principalIdKey: _scope.principalIdResponseKey,
      ).toDomain(),
    );
    await _saveSessionIfSuccess(result);
    return result;
  }

  Future<Result<AuthLoginCheckResult>> loginCheck({required String phone}) {
    return _executor.run(
      () => _authApi.loginCheck(LoginCheckPayload(phone: phone)),
      (raw) => AuthLoginCheckResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  Future<Result<PrincipalAuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) async {
    final result = await _executor.run(
      () => _authApi.loginDirect(
        DirectLoginPayload(phone: phone, ticket: ticket),
      ),
      (raw) => AuthSessionResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
        principalIdKey: _scope.principalIdResponseKey,
      ).toDomain(),
    );
    await _saveSessionIfSuccess(result);
    return result;
  }

  Future<Result<PrincipalAuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _executor.run(
      () => _authApi.loginPassword(
        PasswordLoginPayload(phone: phone, password: password),
      ),
      (raw) => AuthSessionResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
        principalIdKey: _scope.principalIdResponseKey,
      ).toDomain(),
    );
    await _saveSessionIfSuccess(result);
    return result;
  }

  Future<Result<PrincipalAuthSessionResult>> refreshToken() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return Failure(mapServerCodeToAppError(code: 40100, message: '缺少刷新令牌'));
    }

    final result = await _executor.run(
      () => _authApi.refreshToken(
        TokenRefreshPayload(refreshToken: refreshToken),
      ),
      (raw) => AuthSessionResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
        principalIdKey: _scope.principalIdResponseKey,
      ).toDomain(),
    );
    await _saveSessionIfSuccess(result);
    return result;
  }

  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    final result = await _executor.runNoData(
      () => _authApi.resetPassword(
        ResetPasswordPayload(
          phone: phone,
          smsCode: smsCode,
          newPassword: newPassword,
        ),
      ),
    );
    if (result is Success<bool>) {
      await _sessionStore.clearSession();
    }
    return _toVoidResult(result);
  }

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!_scope.supportsChangePassword) {
      return Failure(
        mapServerCodeToAppError(code: 40000, message: '当前身份不支持修改密码'),
      );
    }

    final result = await _executor.runNoData(
      () => _authApi.changePassword(
        ChangePasswordPayload(
          oldPassword: oldPassword,
          newPassword: newPassword,
        ),
      ),
    );
    return _toVoidResult(result);
  }

  Future<Result<void>> logout({String? refreshToken}) async {
    final result = await _executor.runNoData(
      () => _authApi.logout(LogoutPayload(refreshToken: refreshToken)),
    );
    if (result is Success<bool>) {
      await _sessionStore.clearSession();
    }
    return _toVoidResult(result);
  }

  Future<void> _saveSessionIfSuccess(
    Result<PrincipalAuthSessionResult> result,
  ) async {
    if (result case Success<PrincipalAuthSessionResult>(data: final data)) {
      await _sessionStore.saveSession(
        principalId: data.principalId,
        tokenPair: data.tokenPair,
      );
      final hook = onSessionSaved;
      if (hook != null) {
        await hook(data);
      }
    }
  }

  Result<void> _toVoidResult(Result<bool> result) {
    return switch (result) {
      Success<bool>() => const Success<void>(null),
      Failure<bool>(error: final error) => Failure<void>(error),
    };
  }
}
