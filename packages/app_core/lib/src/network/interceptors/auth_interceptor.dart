import 'package:dio/dio.dart';
import 'package:app_core/src/network/network_auth_strategy.dart';
import 'package:app_core/src/session/session_store.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionStore sessionStore,
    required NetworkAuthStrategy authStrategy,
  }) : _sessionStore = sessionStore,
       _authStrategy = authStrategy;

  final SessionStore _sessionStore;
  final NetworkAuthStrategy _authStrategy;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    if (_authStrategy.shouldAttachDeviceId(path)) {
      final deviceId = await _sessionStore.getOrCreateDeviceId();
      options.headers['X-Device-Id'] = deviceId;
    }

    final needsAuth = !_authStrategy.isPublicPath(path);
    if (needsAuth) {
      final accessToken = await _sessionStore.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }
}
