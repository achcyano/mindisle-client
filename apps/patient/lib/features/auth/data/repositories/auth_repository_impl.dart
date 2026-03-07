import 'package:app_core/app_core.dart';
import 'package:patient/data/preference/const.dart';
import 'package:patient/features/auth/data/models/auth_models.dart';
import 'package:patient/features/auth/data/remote/auth_api.dart';
import 'package:patient/features/auth/domain/entities/auth_entities.dart';
import 'package:patient/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required SessionStore sessionStore,
    ApiCallExecutor executor = const ApiCallExecutor(),
  })  : _authApi = authApi,
        _sessionStore = sessionStore,
        _executor = executor;

  final AuthApi _authApi;
  final SessionStore _sessionStore;
  final ApiCallExecutor _executor;

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  }) async {
    final result = await _executor.runNoData(
      () => _authApi.sendSmsCode(
        SendSmsCodeRequest(phone: phone, purpose: purpose),
        forwardedFor: forwardedFor,
      ),
    );
    return _toVoidResult(result);
  }

  @override
  Future<Result<AuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) async {
    final result = await _executor.run(
      () => _authApi.register(
        RegisterRequest(
          phone: phone,
          smsCode: smsCode,
          password: password,
          profile: profile,
        ),
      ),
      (raw) => AuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<LoginCheckResult>> loginCheck({required String phone}) {
    return _executor.run(
      () => _authApi.loginCheck(LoginCheckRequest(phone: phone)),
      (raw) => LoginCheckResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<AuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) async {
    final result = await _executor.run(
      () => _authApi.loginDirect(
        DirectLoginRequest(phone: phone, ticket: ticket),
      ),
      (raw) => AuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<AuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _executor.run(
      () => _authApi.loginPassword(
        PasswordLoginRequest(phone: phone, password: password),
      ),
      (raw) => AuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<AuthSessionResult>> refreshToken() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return Failure(mapServerCodeToAppError(code: 40100, message: '缺少刷新令牌'));
    }

    final result = await _executor.run(
      () => _authApi.refreshToken(
        TokenRefreshRequest(refreshToken: refreshToken),
      ),
      (raw) => AuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    final result = await _executor.runNoData(
      () => _authApi.resetPassword(
        ResetPasswordRequest(
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

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    final result = await _executor.runNoData(
      () => _authApi.logout(LogoutRequest(refreshToken: refreshToken)),
    );
    if (result is Success<bool>) {
      await _sessionStore.clearSession();
    }
    return _toVoidResult(result);
  }

  Future<void> _saveSessionIfSuccess(Result<AuthSessionResult> result) async {
    if (result case Success<AuthSessionResult>(data: final data)) {
      await _sessionStore.saveSession(
        principalId: data.userId,
        tokenPair: data.tokenPair,
      );
      await AppPrefs.hasCompletedFirstLogin.set(true);
    }
  }

  Result<void> _toVoidResult(Result<bool> result) {
    return switch (result) {
      Success<bool>() => const Success(null),
      Failure<bool>(error: final error) => Failure(error),
    };
  }
}
