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

    final response = err.response;
    if (response == null) return false;
    if (response.statusCode != 401) return false;

    final data = response.data;
    if (data is! Map<String, dynamic>) return false;
    return (data['code'] as num?)?.toInt() == 40100;
  }

  DioException _buildReLoginException(RequestOptions requestOptions) {
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: const {
          'code': 40100,
          'message': 'Session expired, please login again',
          'data': null,
        },
      ),
      type: DioExceptionType.badResponse,
      message: 'Session expired, please login again',
    );
  }
}
