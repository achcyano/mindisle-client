import 'package:mindisle_client/core/static.dart';

final class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  factory AppConfig.dev() {
    return AppConfig(
      baseUrl: '$apiScheme://$apiHost:$apiPort',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
