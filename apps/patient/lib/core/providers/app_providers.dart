import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:patient/core/config/app_config.dart';
import 'package:patient/core/static.dart';
import 'package:patient/shared/session/session_expired_signal.dart';
import 'package:patient/shared/session/session_store_impl.dart';

final appConfigProvider = Provider<AppConfig>((_) => buildDevAppConfig());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SessionStoreImpl(secureStorage);
});

final networkAuthStrategyProvider = Provider<NetworkAuthStrategy>((_) {
  return NetworkAuthStrategy(
    authPathPrefix: '$apiPrefix/auth/',
    refreshPath: '$apiPrefix/auth/token/refresh',
    publicPaths: <String>{
      '$apiPrefix/auth/sms-codes',
      '$apiPrefix/auth/register',
      '$apiPrefix/auth/login/check',
      '$apiPrefix/auth/login/direct',
      '$apiPrefix/auth/login/password',
      '$apiPrefix/auth/token/refresh',
      '$apiPrefix/auth/password/reset',
    },
    unauthorizedBusinessCode: 40100,
    principalIdKeys: const <String>['userId'],
    expiredMessage: '登录状态已过期，请重新登录',
  );
});

final refreshDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioFactory.createRefreshDio(config);
});

final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  return TokenRefreshService(
    refreshDio: ref.watch(refreshDioProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    authStrategy: ref.watch(networkAuthStrategyProvider),
  );
});

final appDioProvider = Provider<Dio>((ref) {
  return DioFactory.createAppDio(
    config: ref.watch(appConfigProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    refreshService: ref.watch(tokenRefreshServiceProvider),
    authStrategy: ref.watch(networkAuthStrategyProvider),
    onSessionExpired: ref.read(sessionExpiredEmitterProvider),
  );
});
