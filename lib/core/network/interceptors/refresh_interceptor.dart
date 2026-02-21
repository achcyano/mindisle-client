import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/request_flags.dart';
import 'package:mindisle_client/core/network/token_refresh_service.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/shared/session/session_store.dart';

final class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required TokenRefreshService refreshService,
    required SessionStore sessionStore,
    required void Function() onSessionExpired,
  })  : _dio = dio,
        _refreshService = refreshService,
        _sessionStore = sessionStore,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final TokenRefreshService _refreshService;
  final SessionStore _sessionStore;
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
    if (request.path == '$apiPrefix/auth/token/refresh') return false;
    if (!_hasBearerToken(request)) return false;

    final response = err.response;
    if (response == null) return false;
    if (response.statusCode != 401) return false;

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['code'] as num?)?.toInt() == 40100;
    }
    if (data is Map) {
      return (data['code'] as num?)?.toInt() == 40100;
    }

    // Streaming requests usually fail with ResponseBody on 401.
    return true;
  }

  bool _hasBearerToken(RequestOptions request) {
    final authHeader = request.headers['Authorization'];
    return authHeader is String && authHeader.startsWith('Bearer ');
  }

  DioException _buildReLoginException(RequestOptions requestOptions) {
    const expiredMessage = '\u767b\u5f55\u72b6\u6001\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55';

    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: const {
          'code': 40100,
          'message': expiredMessage,
          'data': null,
        },
      ),
      type: DioExceptionType.badResponse,
      message: expiredMessage,
    );
  }
}
