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
  })  : _dio = dio,
        _refreshService = refreshService,
        _sessionStore = sessionStore;

  final Dio _dio;
  final TokenRefreshService _refreshService;
  final SessionStore _sessionStore;

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
      handler.next(err);
      return;
    }

    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    request.headers['Authorization'] = 'Bearer $token';

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
    if (request.path == '$apiPrefix/auth/token/refresh') return false;

    final response = err.response;
    if (response == null) return false;
    if (response.statusCode != 401) return false;

    final data = response.data;
    if (data is! Map<String, dynamic>) return false;
    return (data['code'] as num?)?.toInt() == 40100;
  }
}
