import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/data/preference/const.dart';
import 'package:mindisle_client/features/auth/data/models/auth_models.dart';
import 'package:mindisle_client/features/auth/data/remote/auth_api.dart';
import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';
import 'package:mindisle_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:mindisle_client/shared/session/session_store.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required SessionStore sessionStore,
  })  : _authApi = authApi,
        _sessionStore = sessionStore;

  final AuthApi _authApi;
  final SessionStore _sessionStore;

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  }) {
    return _runVoid(
      () => _authApi.sendSmsCode(
        SendSmsCodeRequest(phone: phone, purpose: purpose),
        forwardedFor: forwardedFor,
      ),
    );
  }

  @override
  Future<Result<AuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) async {
    final result = await _run(
      () => _authApi.register(
        RegisterRequest(
          phone: phone,
          smsCode: smsCode,
          password: password,
          profile: profile,
        ),
      ),
      (raw) => AuthResponseDto.fromJson(Map<String, dynamic>.from(raw as Map))
          .toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<LoginCheckResult>> loginCheck({required String phone}) {
    return _run(
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
    final result = await _run(
      () => _authApi.loginDirect(
        DirectLoginRequest(phone: phone, ticket: ticket),
      ),
      (raw) => AuthResponseDto.fromJson(Map<String, dynamic>.from(raw as Map))
          .toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<AuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _run(
      () => _authApi.loginPassword(
        PasswordLoginRequest(phone: phone, password: password),
      ),
      (raw) => AuthResponseDto.fromJson(Map<String, dynamic>.from(raw as Map))
          .toDomain(),
    );

    await _saveSessionIfSuccess(result);
    return result;
  }

  @override
  Future<Result<AuthSessionResult>> refreshToken() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return Failure(mapServerCodeToAppError(
        code: 40100,
        message: '\u7f3a\u5c11\u5237\u65b0\u4ee4\u724c',
      ));
    }

    final result = await _run(
      () => _authApi.refreshToken(TokenRefreshRequest(refreshToken: refreshToken)),
      (raw) => AuthResponseDto.fromJson(Map<String, dynamic>.from(raw as Map))
          .toDomain(),
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
    final result = await _runVoid(
      () => _authApi.resetPassword(
        ResetPasswordRequest(
          phone: phone,
          smsCode: smsCode,
          newPassword: newPassword,
        ),
      ),
    );
    if (result is Success<void>) {
      await _sessionStore.clearSession();
    }
    return result;
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    final result = await _runVoid(
      () => _authApi.logout(LogoutRequest(refreshToken: refreshToken)),
    );
    if (result is Success<void>) {
      await _sessionStore.clearSession();
    }
    return result;
  }

  Future<void> _saveSessionIfSuccess(Result<AuthSessionResult> result) async {
    if (result case Success<AuthSessionResult>(data: final data)) {
      await _sessionStore.saveSession(
        userId: data.userId,
        tokenPair: data.tokenPair,
      );
      await AppPrefs.hasCompletedFirstLogin.set(true);
    }
  }

  Future<Result<T>> _run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) dataParser,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<T>.fromJson(json, dataParser);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(code: envelope.code, message: envelope.message),
        );
      }
      return Success(envelope.data as T);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  Future<Result<void>> _runVoid(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<Object?>.fromJson(
        json,
        (raw) => raw,
      );
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(code: envelope.code, message: envelope.message),
        );
      }
      return const Success(null);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }
}

