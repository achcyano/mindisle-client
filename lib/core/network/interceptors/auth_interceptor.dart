import 'package:dio/dio.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/shared/session/session_store.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._sessionStore);

  final SessionStore _sessionStore;

  static const _publicAuthPaths = <String>{
    '$apiPrefix/auth/sms-codes',
    '$apiPrefix/auth/register',
    '$apiPrefix/auth/login/check',
    '$apiPrefix/auth/login/direct',
    '$apiPrefix/auth/login/password',
    '$apiPrefix/auth/token/refresh',
    '$apiPrefix/auth/password/reset',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.startsWith('$apiPrefix/auth/')) {
      final deviceId = await _sessionStore.getOrCreateDeviceId();
      options.headers['X-Device-Id'] = deviceId;
    }

    final needsAuth = !_publicAuthPaths.contains(options.path);
    if (needsAuth) {
      final accessToken = await _sessionStore.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }
}
