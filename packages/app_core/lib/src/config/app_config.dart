final class AppConfig {
  const AppConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
