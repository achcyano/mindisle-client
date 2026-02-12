import 'package:logger/logger.dart';

final logger = Logger();

const appDisplayName = '心岛';

const apiScheme = 'http';
const apiHost = '192.168.1.3';
const apiPort = 8808;
const apiPrefix = '/api/v1';

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
