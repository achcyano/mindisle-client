import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:doctor/core/static.dart';
import 'package:doctor/shared/session/session_expired_signal.dart';
import 'package:doctor/shared/session/session_store_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  return AppConfig(baseUrl: '$apiScheme://$apiHost:$apiPort');
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStoreImpl(ref.watch(secureStorageProvider));
});

final authStrategyProvider = Provider<NetworkAuthStrategy>((_) {
  return NetworkAuthStrategy(
    authPathPrefix: '$apiPrefix/doctor/auth/',
    refreshPath: '$apiPrefix/doctor/auth/token/refresh',
    publicPaths: <String>{
      '$apiPrefix/doctor/auth/sms-codes',
      '$apiPrefix/doctor/auth/register',
      '$apiPrefix/doctor/auth/login/password',
      '$apiPrefix/doctor/auth/token/refresh',
      '$apiPrefix/doctor/auth/password/reset',
    },
    principalIdKeys: const <String>['doctorId'],
    unauthorizedBusinessCode: 40100,
  );
});

final refreshDioProvider = Provider<Dio>((ref) {
  return DioFactory.createRefreshDio(ref.watch(appConfigProvider));
});

final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  return TokenRefreshService(
    refreshDio: ref.watch(refreshDioProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    authStrategy: ref.watch(authStrategyProvider),
  );
});

final appDioProvider = Provider<Dio>((ref) {
  return DioFactory.createAppDio(
    config: ref.watch(appConfigProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    refreshService: ref.watch(tokenRefreshServiceProvider),
    authStrategy: ref.watch(authStrategyProvider),
    onSessionExpired: ref.read(sessionExpiredEmitterProvider),
  );
});
