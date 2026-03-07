import 'package:app_core/app_core.dart';
import 'package:patient/core/static.dart';

AppConfig buildDevAppConfig() {
  return AppConfig(
    baseUrl: '$apiScheme://$apiHost:$apiPort',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}
