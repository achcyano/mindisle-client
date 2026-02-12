import 'package:dio/dio.dart';
import 'package:mindisle_client/features/auth/data/models/auth_models.dart';

final class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> sendSmsCode(
    SendSmsCodeRequest request, {
    String? forwardedFor,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/sms-codes',
      data: request.toJson(),
      options: Options(
        headers: {
          if (forwardedFor != null && forwardedFor.isNotEmpty)
            'X-Forwarded-For': forwardedFor,
        },
      ),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loginCheck(LoginCheckRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login/check',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loginDirect(DirectLoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login/direct',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loginPassword(
    PasswordLoginRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login/password',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> refreshToken(TokenRefreshRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/token/refresh',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> resetPassword(
    ResetPasswordRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/password/reset',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> logout(LogoutRequest? request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      data: request?.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
