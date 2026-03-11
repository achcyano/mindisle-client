import 'package:app_core/src/config/app_config.dart';
import 'package:logger/logger.dart';

final logger = Logger();

final class SharedServerConfig {
  const SharedServerConfig({
    required this.apiScheme,
    required this.apiHost,
    required this.apiPort,
    required this.apiPrefix,
  });

  final String apiScheme;
  final String apiHost;
  final int apiPort;
  final String apiPrefix;

  String get baseUrl => '$apiScheme://$apiHost:$apiPort';

  AppConfig toAppConfig({
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
  }) {
    return AppConfig(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  Uri buildApiUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: apiScheme,
      host: apiHost,
      port: apiPort,
      path: normalizedPath,
      queryParameters: queryParameters,
    );
  }
}

const defaultSharedServerConfig = SharedServerConfig(
  apiScheme: 'http',
  apiHost: '10.21.169.131',
  apiPort: 80,
  apiPrefix: '/api/v1',
);
