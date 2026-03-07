import 'package:dio/dio.dart';
import 'package:app_core/src/network/network_auth_strategy.dart';
import 'package:app_core/src/network/request_flags.dart';
import 'package:app_core/src/network/token_refresh_service.dart';
import 'package:app_core/src/session/session_store.dart';

final class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required TokenRefreshService refreshService,
    required SessionStore sessionStore,
    required NetworkAuthStrategy authStrategy,
    required void Function() onSessionExpired,
  }) : _dio = dio,
       _refreshService = refreshService,
       _sessionStore = sessionStore,
       _authStrategy = authStrategy,
       _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final TokenRefreshService _refreshService;
  final SessionStore _sessionStore;
  final NetworkAuthStrategy _authStrategy;
  final void Function() _onSessionExpired;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldHandle(err)) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshService.refresh();
    if (!refreshed) {
      await _sessionStore.clearSession();
      _onSessionExpired();
      handler.next(_buildReLoginException(err.requestOptions));
      return;
    }

    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      await _sessionStore.clearSession();
      _onSessionExpired();
      handler.next(_buildReLoginException(err.requestOptions));
      return;
    }

    final request = err.requestOptions;
    request.headers['Authorization'] = 'Bearer $token';
    request.extra[RequestFlags.retriedAfterRefresh] = true;

    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _shouldHandle(DioException err) {
    final request = err.requestOptions;
    if (request.extra[RequestFlags.skipRefresh] == true) return false;
    if (request.extra[RequestFlags.retriedAfterRefresh] == true) return false;
    if (request.path == _authStrategy.refreshPath) return false;
    if (!_hasBearerToken(request)) return false;

    final response = err.response;
    if (response == null) return false;
    if (response.statusCode != 401) return false;

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final code = (data['code'] as num?)?.toInt();
      return code == null || code == _authStrategy.unauthorizedBusinessCode;
    }
    if (data is Map) {
      final code = (data['code'] as num?)?.toInt();
      return code == null || code == _authStrategy.unauthorizedBusinessCode;
    }

    return true;
  }

  bool _hasBearerToken(RequestOptions request) {
    final authHeader = request.headers['Authorization'];
    return authHeader is String && authHeader.startsWith('Bearer ');
  }

  DioException _buildReLoginException(RequestOptions requestOptions) {
    final expiredMessage = _authStrategy.expiredMessage;

    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: {
          'code': _authStrategy.unauthorizedBusinessCode,
          'message': expiredMessage,
          'data': null,
        },
      ),
      type: DioExceptionType.badResponse,
      message: expiredMessage,
    );
  }
}
