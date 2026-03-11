import 'package:app_core/src/network/auth_scope_config.dart';
import 'package:dio/dio.dart';
import 'package:models/models.dart';

final class ScopedAuthApiClient {
  ScopedAuthApiClient(this._dio, {required this.scope});

  final Dio _dio;
  final AuthScopeConfig scope;

  Future<Map<String, dynamic>> sendSmsCode(
    SendSmsCodePayload payload, {
    Map<String, String>? headers,
  }) {
    return _post(scope.smsCodesPath, data: payload.toJson(), headers: headers);
  }

  Future<Map<String, dynamic>> register(RegisterPayload payload) {
    return _post(scope.registerPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> loginCheck(LoginCheckPayload payload) {
    return _post(scope.loginCheckPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> loginDirect(DirectLoginPayload payload) {
    return _post(scope.loginDirectPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> loginPassword(PasswordLoginPayload payload) {
    return _post(scope.loginPasswordPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> refreshToken(TokenRefreshPayload payload) {
    return _post(scope.refreshPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> resetPassword(ResetPasswordPayload payload) {
    return _post(scope.resetPasswordPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> changePassword(ChangePasswordPayload payload) {
    return _post(scope.changePasswordPath, data: payload.toJson());
  }

  Future<Map<String, dynamic>> logout(LogoutPayload? payload) {
    return _post(scope.logoutPath, data: payload?.toJson());
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Object? data,
    Map<String, String>? headers,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: headers == null || headers.isEmpty
          ? null
          : Options(headers: headers),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
