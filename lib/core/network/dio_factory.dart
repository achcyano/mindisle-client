import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mindisle_client/core/config/app_config.dart';
import 'package:mindisle_client/core/network/interceptors/auth_interceptor.dart';
import 'package:mindisle_client/core/network/interceptors/refresh_interceptor.dart';
import 'package:mindisle_client/core/network/token_refresh_service.dart';
import 'package:mindisle_client/shared/session/session_store.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final class DioFactory {
  static Dio createRefreshDio(AppConfig config) {
    return Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );
  }

  static Dio createAppDio({
    required AppConfig config,
    required SessionStore sessionStore,
    required TokenRefreshService refreshService,
    required void Function() onSessionExpired,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(AuthInterceptor(sessionStore));
    dio.interceptors.add(
      RefreshInterceptor(
        dio: dio,
        refreshService: refreshService,
        sessionStore: sessionStore,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (kDebugMode) {
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
