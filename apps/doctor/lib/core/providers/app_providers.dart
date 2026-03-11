import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:doctor/core/auth_scope.dart';
import 'package:doctor/shared/session/session_expired_signal.dart';
import 'package:doctor/shared/session/session_store_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final sharedServerConfigProvider = Provider<SharedServerConfig>(
  (_) => defaultSharedServerConfig,
);

final appConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(sharedServerConfigProvider).toAppConfig();
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStoreImpl(ref.watch(secureStorageProvider));
});

final authScopeConfigProvider = Provider<AuthScopeConfig>((_) {
  return doctorAuthScopeConfig;
});

final authStrategyProvider = Provider<NetworkAuthStrategy>((ref) {
  return ref.watch(authScopeConfigProvider).toNetworkAuthStrategy();
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
