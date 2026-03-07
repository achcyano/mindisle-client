import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:app_core/src/config/app_config.dart';
import 'package:app_core/src/network/interceptors/auth_interceptor.dart';
import 'package:app_core/src/network/interceptors/refresh_interceptor.dart';
import 'package:app_core/src/network/network_auth_strategy.dart';
import 'package:app_core/src/network/token_refresh_service.dart';
import 'package:app_core/src/session/session_store.dart';

final class DioFactory {
  static Dio createRefreshDio(
    AppConfig config, {
    bool enableLogger = kDebugMode,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );
    if (enableLogger) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
      );
    }
    return dio;
  }

  static Dio createAppDio({
    required AppConfig config,
    required SessionStore sessionStore,
    required TokenRefreshService refreshService,
    required NetworkAuthStrategy authStrategy,
    required void Function() onSessionExpired,
    bool enableLogger = kDebugMode,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(sessionStore: sessionStore, authStrategy: authStrategy),
    );
    dio.interceptors.add(
      RefreshInterceptor(
        dio: dio,
        refreshService: refreshService,
        sessionStore: sessionStore,
        authStrategy: authStrategy,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (enableLogger) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
      );
    }

    return dio;
  }
}
