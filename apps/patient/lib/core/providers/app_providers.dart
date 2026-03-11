import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:patient/core/auth_scope.dart';
import 'package:patient/core/config/app_config.dart';
import 'package:patient/shared/session/session_expired_signal.dart';
import 'package:patient/shared/session/session_store_impl.dart';

final sharedServerConfigProvider = Provider<SharedServerConfig>(
  (_) => defaultSharedServerConfig,
);

final appConfigProvider = Provider<AppConfig>((_) => buildDevAppConfig());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStoreImpl(ref.watch(secureStorageProvider));
});

final authScopeConfigProvider = Provider<AuthScopeConfig>((_) {
  return patientAuthScopeConfig;
});

final networkAuthStrategyProvider = Provider<NetworkAuthStrategy>((ref) {
  return ref.watch(authScopeConfigProvider).toNetworkAuthStrategy();
});

final refreshDioProvider = Provider<Dio>((ref) {
  return DioFactory.createRefreshDio(ref.watch(appConfigProvider));
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
